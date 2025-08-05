// AudioManager.swift
// Unified audio manager for microphone and system audio capture

import AVFoundation
import Foundation
import SwiftUI
import OSLog
import Combine

/// Manages audio capture from microphone and system audio and handles real-time transcription via OpenAI
@MainActor
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var transcriptChunks: [TranscriptChunk] = []
    @Published var isRecording = false
    @Published var errorMessage: String?
    @Published var micAudioLevel: Float = 0.0
    @Published var systemAudioLevel: Float = 0.0
    
    private var audioEngine = AVAudioEngine()
    private var micSocketTask: URLSessionWebSocketTask?
    private var systemSocketTask: URLSessionWebSocketTask?
    private let realtimeURL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!

    // Unique identifier for the current recording session
    private var sessionID = UUID()
    
    // ProcessTap properties
    private var processTap: ProcessTap?
    private let audioProcessController = AudioProcessController()
    private let permission = AudioRecordingPermission()
    private let tapQueue = DispatchQueue(label: "io.meetingnotes.audiotap", qos: .userInitiated)
    private var isTapActive = false
    private var isRestartingSystemTap = false
    
    // Add properties near the top, after existing private vars
    private var micRetryCount = 0
    private let maxMicRetries = 3
    
    // Add current interim transcripts per source
    private var currentInterim: [AudioSource: String] = [.mic: "", .system: ""]
    
    // Add ping timers to keep WebSocket connections alive
    private var pingTimers: [AudioSource: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // Session refresh timers to prevent 30-minute expiry
    private var sessionRefreshTimers: [AudioSource: Timer] = [:]

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                               object: audioEngine,
                                               queue: .main) { [weak self] _ in
            self?.handleAudioEngineConfigurationChange()
        }
        
        // Activate the process controller to start monitoring audio-producing apps
        audioProcessController.activate()
        
        // When the list of running applications changes, check if we need to restart the system audio tap
        NSWorkspace.shared.publisher(for: \.runningApplications)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.isTapActive else { return }
                
                print("🎤 Running applications changed, checking if tap restart is needed.")
                Task {
                    await self.restartSystemAudioTapIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRecording() {
        print("Starting recording...")
        
        // Bump session ID so any old async callbacks can be ignored
        sessionID = UUID()

        // Clear any previous errors
        DispatchQueue.main.async {
            self.errorMessage = nil
        }

        // Stop any in-progress recording
        stopRecordingInternal()

        // Validate API key and account status before connecting
        Task {
            let validationResult = await APIKeyValidator.shared.validateCurrentAPIKey()
            switch validationResult {
            case .failure(let error):
                let errorMsg = error.localizedDescription
                print("❌ API key validation failed: \(errorMsg)")
                DispatchQueue.main.async {
                    self.errorMessage = errorMsg
                }
            case .success:
                // Proceed with taps after cleanup
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Start microphone capture
                    self.startMicrophoneTap()
                    // Start system audio capture asynchronously
                    Task {
                        await self.startSystemAudioTap()
                    }
                }
            }
        }
    }
    
    private func stopRecordingInternal() {
        print("Internal cleanup...")
        
        // Stop system audio capture
        if isTapActive {
            self.processTap?.invalidate()
            self.processTap = nil
            isTapActive = false
            print("System audio tap invalidated")
        }
        
        // Stop microphone capture
        cleanupAudioEngine()
        
        // Close WebSocket
        micSocketTask?.cancel(with: .normalClosure, reason: nil)
        micSocketTask = nil
        systemSocketTask?.cancel(with: .normalClosure, reason: nil)
        systemSocketTask = nil
        
        // Invalidate ping timers
        pingTimers.values.forEach { $0.invalidate() }
        pingTimers.removeAll()
        
        // Invalidate session refresh timers
        sessionRefreshTimers.values.forEach { $0.invalidate() }
        sessionRefreshTimers.removeAll()
        
        // Reset state
        // (isRecording already cleared in stopRecording)
        
        print("Internal cleanup completed")
    }
    
    private func restartMicrophone() {
        guard isRecording, micRetryCount < maxMicRetries else { return }
        
        print("🔄 Restarting microphone capture (attempt \(micRetryCount + 1))")
        micRetryCount += 1
        
        cleanupAudioEngine()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startMicrophoneTap()
        }
    }

    /// Starts a microphone tap without creating a new OpenAI connection (used when also capturing system audio)
    private func startMicrophoneTap() {
        print("🎤 Starting microphone tap...")
        
        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                             sampleRate: 24000,
                                             channels: 1,
                                             interleaved: false) else {
                print("❌ Failed to create target audio format for mic tap")
                self.restartMicrophone()
                return
            }

            guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
                print("❌ Failed to create audio converter for mic tap")
                self.restartMicrophone()
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                
                // Check for invalid buffer
                guard buffer.frameLength > 0, buffer.floatChannelData != nil else {
                    print("❌ Invalid mic buffer detected - restarting")
                    self.restartMicrophone()
                    return
                }
                
                // Calculate audio level for visual indicator
                if let ch = buffer.floatChannelData?[0] {
                    let frameCount = Int(buffer.frameLength)
                    let samples = UnsafeBufferPointer(start: ch, count: frameCount)
                    let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameCount))
                    
                    // Update the published audio level on main thread
                    DispatchQueue.main.async {
                        self.micAudioLevel = rms
                        AudioLevelManager.shared.updateMicLevel(rms)
                    }
                }
                
                self.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat, source: .mic)
            }

            audioEngine.prepare()
            try audioEngine.start()
            connectToOpenAIRealtime(source: .mic)
            print("✅ Microphone tap started successfully")
            micRetryCount = 0  // Reset on success
            
        } catch {
            print("❌ Failed to start microphone tap: \(error)")
            self.restartMicrophone()
        }
    }
    
    private func cleanupAudioEngine() {
        print("🧹 Cleaning up audio engine...")
        
        // Stop the engine first
        if audioEngine.isRunning {
            audioEngine.stop()
            print("⏹️ Audio engine stopped")
        }
        
        // Remove any existing taps on the input node
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        print("🔇 Input tap removed")
        
        // Reset the audio engine - this removes all connections and taps
        audioEngine.reset()
        print("🔄 Audio engine reset")
        
        // Create a fresh audio engine to ensure clean state
        audioEngine = AVAudioEngine()
        print("✨ Fresh audio engine created")
    }
    
    private func startSystemAudioTap(isRestart: Bool = false) async {
        print(isRestart ? "🎧 Restarting system audio tap logic..." : "🎧 Starting system audio tap for the first time...")
        
        if !isRestart {
            guard await checkSystemAudioPermissions() else {
                let errorMsg = "System audio recording permission denied."
                print("❌ \(errorMsg)")
                self.errorMessage = errorMsg
                return
            }
        }
        
        // Get all running processes that are producing audio
        let allProcessObjectIDs = audioProcessController.processes.map { $0.objectID }
        if allProcessObjectIDs.isEmpty {
            print("⚠️ No audio-producing processes found. System audio tap might not capture anything.")
        }
        
        // Configure the tap for system-wide audio
        let target = TapTarget.systemAudio(processObjectIDs: allProcessObjectIDs)
        let newTap = ProcessTap(target: target)
        newTap.activate()
        
        // Check for activation errors
        if let tapError = newTap.errorMessage {
            let errorMsg = "Failed to activate system audio tap: \(tapError)"
            print("❌ \(errorMsg)")
            self.errorMessage = errorMsg
            if !isRestart { stopRecording() }
            return
        }
        
        self.processTap = newTap
        self.isTapActive = true
        
        // Start receiving audio data from the tap
        do {
            try startTapIO(newTap)
            
            if !isRestart {
                connectToOpenAIRealtime(source: .system)
                self.isRecording = true
                AudioLevelManager.shared.updateRecordingState(true)
            }
            print("✅ System audio tap started successfully (isRestart: \(isRestart))")
            
        } catch {
            let errorMsg = "Failed to start system audio tap IO: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            self.errorMessage = errorMsg
            newTap.invalidate()
            self.isTapActive = false
            if !isRestart { stopRecording() }
        }
    }
    
    private func restartSystemAudioTapIfNeeded() async {
        let newProcessObjectIDs = Set(audioProcessController.processes.map { $0.objectID })
        let currentProcessObjectIDs: Set<AudioObjectID>
        
        if case .systemAudio(let processObjectIDs) = self.processTap?.target {
            currentProcessObjectIDs = Set(processObjectIDs)
        } else {
            currentProcessObjectIDs = []
        }
        
        if newProcessObjectIDs != currentProcessObjectIDs {
            print("Process list has changed. Restarting system audio tap.")
            await restartSystemAudioTap()
        } else {
            print("Process list is the same. No restart needed.")
        }
    }

    private func restartSystemAudioTap() async {
        print("🔄 Restarting system audio tap...")

        guard isRecording else {
            print("Recording was stopped, aborting tap restart.")
            return
        }
        
        isRestartingSystemTap = true
        defer { isRestartingSystemTap = false }
        
        // 1. Invalidate existing tap
        if isTapActive {
            processTap?.invalidate()
            processTap = nil
            isTapActive = false
            print("System audio tap invalidated for restart.")
        }
        
        // A small delay to let things settle.
        try? await Task.sleep(for: .milliseconds(250))
        
        guard self.isRecording else {
            print("Recording was stopped during tap restart. Aborting.")
            return
        }

        // 2. Start a new one, but don't re-connect to OpenAI or change recording state
        await startSystemAudioTap(isRestart: true)
    }

    @MainActor
    private func checkSystemAudioPermissions() async -> Bool {
        if permission.status == .authorized {
            return true
        }
        
        permission.request()
        
        // Poll for a short time to see if permission is granted
        for _ in 0..<10 {
            if permission.status == .authorized {
                return true
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        return permission.status == .authorized
    }
    
    private func startTapIO(_ tap: ProcessTap) throws {
        guard var streamDescription = tap.tapStreamDescription else {
            throw NSError(domain: "AudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get audio format from tap."])
        }

        guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
            throw NSError(domain: "AudioManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAudioFormat from tap."])
        }

        try tap.run(on: tapQueue) { [weak self] _, inInputData, _, _, _ in
            guard let self = self,
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: inInputData, deallocator: nil) else {
                return
            }

            let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                           sampleRate: 24000,
                                           channels: 1,
                                           interleaved: false)!

            guard let converter = AVAudioConverter(from: format, to: targetFormat) else {
                return
            }
            
            // Calculate audio level for visual indicator
            if let ch = buffer.floatChannelData?[0] {
                let frameCount = Int(buffer.frameLength)
                let samples = UnsafeBufferPointer(start: ch, count: frameCount)
                let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameCount))
                
                // Update the published audio level on main thread
                DispatchQueue.main.async {
                    self.systemAudioLevel = rms
                    AudioLevelManager.shared.updateSystemLevel(rms)
                }
            }
            
            self.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat, source: .system)
            
        } invalidationHandler: { [weak self] _ in
            guard let self else { return }
            print("Audio tap was invalidated.")

            if !self.isRestartingSystemTap {
                print("Tap invalidated unexpectedly. Restarting system audio tap.")
                Task {
                    await self.restartSystemAudioTap()
                }
            } else {
                print("Tap invalidated as part of a restart. Not stopping recording.")
            }
        }
    }
    
    func stopRecording() {
        // Immediately mark as not recording to prevent stale callbacks
        self.isRecording = false
        AudioLevelManager.shared.updateRecordingState(false)
        print("Stopping recording...")
        
        // Reset audio levels
        micAudioLevel = 0.0
        systemAudioLevel = 0.0
        AudioLevelManager.shared.updateMicLevel(0.0)
        AudioLevelManager.shared.updateSystemLevel(0.0)
        
        // Stop system audio capture
        if isTapActive {
            self.processTap?.invalidate()
            self.processTap = nil
            isTapActive = false
            print("System audio tap invalidated")
        }
        
        // Stop microphone capture
        cleanupAudioEngine()
        micRetryCount = 0
        
        // Close WebSocket
        micSocketTask?.cancel(with: .normalClosure, reason: nil)
        micSocketTask = nil
        systemSocketTask?.cancel(with: .normalClosure, reason: nil)
        systemSocketTask = nil
        
        // Invalidate ping timers
        pingTimers.values.forEach { $0.invalidate() }
        pingTimers.removeAll()
        
        // Invalidate session refresh timers
        sessionRefreshTimers.values.forEach { $0.invalidate() }
        sessionRefreshTimers.removeAll()
        
        print("Recording stopped")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat, source: AudioSource) {
        let processBuffer = buffer
        
        // Convert to target format (24kHz int16 mono) in a single step – AVAudioConverter will handle resampling and downmixing
        let outputFrameCapacity = AVAudioFrameCount(Double(processBuffer.frameLength) * targetFormat.sampleRate / processBuffer.format.sampleRate)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            return
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return processBuffer
        }
        
        guard status == .haveData, error == nil else {
            return
        }
        
        // Convert to Data for OpenAI
        guard let channelData = outputBuffer.int16ChannelData?[0] else {
            return
        }
        
        let frameCount = Int(outputBuffer.frameLength)
        let data = Data(bytes: channelData, count: frameCount * 2)
        
        sendAudioData(data, source: source)
    }
    
    private func connectToOpenAIRealtime(source: AudioSource) {
        guard let key = KeychainHelper.shared.getAPIKey(), !key.isEmpty else {
            let errorMsg = ErrorMessage.noAPIKey
            print("❌ \(errorMsg)")
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
            return
        }

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: realtimeURL)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let task = session.webSocketTask(with: request)
        
        // Add connection monitoring
        task.resume()
        
        // Set up ping timer to keep connection alive
        pingTimers[source]?.invalidate()
        let pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let task = source == .mic ? self.micSocketTask : self.systemSocketTask
            guard let socket = task, socket.state == .running else { return }
            socket.sendPing { error in
                if let error = error {
                    print("❌ Ping failed for \(source): \(error)")
                } else {
                    print("🏓 Ping sent for \(source)")
                }
            }
        }
        pingTimers[source] = pingTimer
        
        // Set up session refresh timer to prevent 30-minute expiry (refresh after 28 minutes)
        sessionRefreshTimers[source]?.invalidate()
        let sessionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 28 * 60.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            print("📝 Proactively refreshing session for \(source) to prevent expiry...")
            self.connectToOpenAIRealtime(source: source)
        }
        sessionRefreshTimers[source] = sessionRefreshTimer
        
        let thisSession = sessionID
        // Monitor connection state (ignore if session changed or recording stopped)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self, weak task] in
            guard let self = self, self.sessionID == thisSession, self.isRecording else { return }
            guard let task = task, task.state != .running else { return }
            let errorMsg = ErrorMessage.connectionTimeout
            print("❌ \(errorMsg)")
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
        }

        // Send initial configuration
        let config: [String: Any] = [
            "type": "transcription_session.update",
            "session": [
                "input_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "gpt-4o-mini-transcribe",
                    "language": "en"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 200
                ]
            ]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: config)
            if let jsonStr = String(data: jsonData, encoding: .utf8) {
                task.send(.string(jsonStr)) { [weak self] error in
                    if let error = error {
                        guard let self = self, self.sessionID == thisSession else { return }

                        // Ignore cancellation errors, which are expected when stopping a session.
                        if (error as? URLError)?.code == .cancelled {
                            return
                        }

                        let errorMsg = "\(ErrorMessage.configurationFailed): \(ErrorHandler.shared.handleError(error))"
                        print("❌ \(errorMsg)")
                        DispatchQueue.main.async {
                            self.errorMessage = errorMsg
                        }
                    }
                }
            }
        } catch {
            let errorMsg = "\(ErrorMessage.configurationFailed): \(ErrorHandler.shared.handleError(error))"
            print("❌ \(errorMsg)")
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
        }

        switch source {
        case .mic:
            micSocketTask = task
        case .system:
            systemSocketTask = task
        }

        receiveMessage(for: source, sessionID: thisSession)
        print("🌐 Connected to OpenAI Realtime (\(source))")
    }

    private func receiveMessage(for source: AudioSource, sessionID: UUID) {
        let task: URLSessionWebSocketTask? = (source == .mic) ? micSocketTask : systemSocketTask
        task?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.parseRealtimeEvent(text, source: source)
                case .data:
                    break
                @unknown default:
                    break
                }
                // Continue loop for this session
                if let self = self, self.sessionID == sessionID {
                    self.receiveMessage(for: source, sessionID: sessionID)
                }
            case .failure(let error):
                guard let self = self, self.sessionID == sessionID else { return } // Stale callback
                // Ignore errors caused by intentional socket closure after recording stops
                if self.isRecording == false { return }

                let errorMsg = self.handleWebSocketError(error, source: source)
                print("❌ Receive error (\(source)): \(error)")
                
                // Check if this is a session expiry - if so, don't show as persistent error
                let isSessionExpiry = errorMsg == ErrorMessage.sessionExpired
                
                if isSessionExpiry {
                    // For session expiry, show temporary message
                    DispatchQueue.main.async {
                        self.errorMessage = errorMsg
                        // Clear the message after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if self.errorMessage == errorMsg {
                                self.errorMessage = nil
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = errorMsg
                    }
                    
                    // Only attempt reconnect for network errors, not API errors
                    if ErrorHandler.shared.shouldRetry(error) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            guard let self = self, self.isRecording, self.sessionID == sessionID else { return }
                            self.connectToOpenAIRealtime(source: source)
                        }
                    }
                }
            }
        }
    }
    
    private func handleWebSocketError(_ error: Error, source: AudioSource) -> String {
        // Check for session expiry in error description first
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("session hit the maximum duration") ||
           errorDescription.contains("session expired") {
            // Handle session expiry by automatically restarting the connection
            print("📝 Session expired for \(source) (WebSocket error), attempting to restart connection...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self, self.isRecording else { return }
                self.connectToOpenAIRealtime(source: source)
            }
            // Return session expired message but don't stop recording
            return ErrorMessage.sessionExpired
        }
        
        // Check for WebSocket close codes
        if let closeCode = (error as NSError?)?.userInfo["closeCode"] as? Int {
            return ErrorHandler.shared.handleWebSocketCloseCode(closeCode)
        }
        
        // Use centralized error handler for all other errors
        return ErrorHandler.shared.handleError(error)
    }
    


    private func parseRealtimeEvent(_ text: String, source: AudioSource) {
        // Parse JSON message
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        // Early error handling for any payload with "error" key
        if let errorDict = json["error"] as? [String: Any] {
            let errorType = errorDict["type"] as? String ?? "unknown_error"
            let errorCode = errorDict["code"] as? String ?? ""
            let errorMessage = errorDict["message"] as? String ?? "Unknown error occurred"
            print("❌ OpenAI Realtime API Error (\(source)) - Type: \(errorType), Code: \(errorCode), Message: \(errorMessage)")

            // Map common error codes to user-friendly messages
            let userFriendlyMessage: String
            switch errorCode {
            case "insufficient_quota", "quota_exceeded":
                userFriendlyMessage = ErrorMessage.insufficientFunds
            case "invalid_api_key", "authentication_failed":
                userFriendlyMessage = ErrorMessage.invalidAPIKey
            case "rate_limit_exceeded":
                userFriendlyMessage = ErrorMessage.rateLimited
            case "server_error":
                userFriendlyMessage = ErrorMessage.apiServerError
            case "access_denied", "forbidden":
                userFriendlyMessage = ErrorMessage.accessForbidden
            case "session_expired":
                // Handle session expiry by automatically restarting the connection
                print("📝 Session expired for \(source), attempting to restart connection...")
                userFriendlyMessage = ErrorMessage.sessionExpired
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isRecording else { return }
                    self.connectToOpenAIRealtime(source: source)
                }
                // Show informational message but don't stop recording
                DispatchQueue.main.async {
                    self.errorMessage = userFriendlyMessage
                    // Clear the message after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if self.errorMessage == userFriendlyMessage {
                            self.errorMessage = nil
                        }
                    }
                }
                return
            default:
                // Check for session expiry in the error message
                if errorMessage.lowercased().contains("session hit the maximum duration") ||
                   errorMessage.lowercased().contains("session expired") {
                    // Handle session expiry by automatically restarting the connection
                    print("📝 Session expired for \(source), attempting to restart connection...")
                    userFriendlyMessage = ErrorMessage.sessionExpired
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        guard let self = self, self.isRecording else { return }
                        self.connectToOpenAIRealtime(source: source)
                    }
                    // Show informational message but don't stop recording
                    DispatchQueue.main.async {
                        self.errorMessage = userFriendlyMessage
                        // Clear the message after a few seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if self.errorMessage == userFriendlyMessage {
                                self.errorMessage = nil
                            }
                        }
                    }
                    return
                }
                // Check if this is a transcription failure (often indicates insufficient funds)
                else if errorMessage.lowercased().contains("input transcription failed") ||
                        errorMessage.lowercased().contains("transcription failed") {
                    userFriendlyMessage = "\(errorMessage)\n\nNote: This error typically occurs when your OpenAI account has insufficient funds. Please check your account balance and add credits if needed."
                } else {
                    userFriendlyMessage = "Transcription error: \(errorMessage)"
                }
            }

            DispatchQueue.main.async {
                self.errorMessage = userFriendlyMessage
                // Stop recording when transcription errors occur
                if self.isRecording {
                    self.stopRecording()
                }
            }
            return
        }

        guard let type = json["type"] as? String else { return }
      
        // Check for general failure status in any event
        if let status = json["status"] as? String, status == "failed" {
            let itemId = json["item_id"] as? String ?? json["id"] as? String ?? "unknown"
            print("❌ Event failed (\(source)): type=\(type), item=\(itemId)")
            let errorMessage = "Transcription failed for \(type) (item: \(itemId))\n\nNote: This error typically occurs when your OpenAI account has insufficient funds. Please check your account balance and add credits if needed."
            DispatchQueue.main.async {
                self.errorMessage = errorMessage
                // Stop recording when transcription errors occur
                if self.isRecording {
                    self.stopRecording()
                }
            }
            return
        }

        // Debug logging for key events (can be removed later)
        if type.contains("transcription") || type.contains("error") {
            print("🔍 Event (\(source)): \(type) - \(String(data: data, encoding: .utf8) ?? "invalid")")
        }

        switch type {
        case "conversation.item.input_audio_transcription.delta":
            if let delta = json["delta"] as? String {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // Safely accumulate interim text for this source
                    self.currentInterim[source, default: ""] += delta

                    // Remove previous interim chunk from the same source (if any)
                    if let lastIndex = self.transcriptChunks.lastIndex(where: { !$0.isFinal && $0.source == source }) {
                        self.transcriptChunks.remove(at: lastIndex)
                    }

                    // Append updated interim chunk
                    let chunk = TranscriptChunk(
                        timestamp: Date(),
                        source: source,
                        text: self.currentInterim[source] ?? "",
                        isFinal: false
                    )
                    self.transcriptChunks.append(chunk)
                }
            }
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    // Remove any interim chunks for this source
                    self.transcriptChunks.removeAll { !$0.isFinal && $0.source == source }

                    // Append final chunk
                    let chunk = TranscriptChunk(
                        timestamp: Date(),
                        source: source,
                        text: transcript,
                        isFinal: true
                    )
                    self.transcriptChunks.append(chunk)

                    // Reset interim buffer for this source
                    self.currentInterim[source] = ""
                }
            } else if let status = json["status"] as? String, status == "failed" {
                // Handle transcription failure (often due to insufficient credits)
                let itemId = json["item_id"] as? String ?? "unknown"
                print("❌ Transcription failed for item: \(itemId)")
                let errorMessage = "Audio transcription failed for item: \(itemId)\n\nNote: This error typically occurs when your OpenAI account has insufficient funds. Please check your account balance and add credits if needed."
                DispatchQueue.main.async {
                    self.errorMessage = errorMessage
                    // Stop recording when transcription errors occur
                    if self.isRecording {
                        self.stopRecording()
                    }
                }
            }
        case "error":
            // This case is now handled by the early error handling above.
            // If we reach here, it means the error was not caught by the early check.
            // We can add specific handling for this case if needed, but for now,
            // the early error handling covers it.
            break
        case "session.updated", "session.created":
            // Log session events for debugging
            print("📋 Session event (\(source)): \(type)")
        case "response.done", "response.created":
            // Log response events for debugging (these don't contain transcription data)
            print("🔄 Response event (\(source)): \(type)")
        case "rate_limits.updated":
            // Log rate limit updates
            if let rateLimits = json["rate_limits"] as? [[String: Any]] {
                for limit in rateLimits {
                    if let name = limit["name"] as? String,
                       let remaining = limit["remaining"] as? Int,
                       let total = limit["limit"] as? Int {
                        print("📊 Rate limit (\(source)) - \(name): \(remaining)/\(total)")
                        
                        // Warn when approaching limits
                        if name == "tokens" && remaining < 1000 {
                            print("⚠️ Warning: Low token balance remaining: \(remaining)")
                        }
                    }
                }
            }
        default:
            break
        }
    }

    private func sendAudioData(_ data: Data, source: AudioSource) {
        let task: URLSessionWebSocketTask? = (source == .mic) ? micSocketTask : systemSocketTask

        guard let socket = task, socket.state == .running else { return }

        let base64 = data.base64EncodedString()
        let message: [String: Any] = ["type": "input_audio_buffer.append", "audio": base64]
        
        let thisSession = self.sessionID
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            if let jsonStr = String(data: jsonData, encoding: .utf8) {
                socket.send(.string(jsonStr)) { [weak self] error in
                    if let error = error {
                        guard let self = self, self.sessionID == thisSession else { return }

                        // Ignore cancellation errors, which are expected when stopping recording.
                        if (error as? URLError)?.code == .cancelled {
                            return
                        }
                        print("❌ Send error (\(source)): \(error)")
                    }
                }
            }
        } catch {
            print("❌ JSON send error")
        }
    }
    
    private func handleAudioEngineConfigurationChange() {
        print("🔔 Audio engine configuration changed - restarting mic")
        restartMicrophone()
    }
} 
