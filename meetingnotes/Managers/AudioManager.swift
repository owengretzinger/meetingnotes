// AudioManager.swift
// Unified audio manager for microphone and system audio capture

import AVFoundation
import Foundation
import SwiftUI
import OSLog

/// Manages audio capture from microphone and system audio and handles real-time transcription via OpenAI
@MainActor
class AudioManager: NSObject, ObservableObject {
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
    
    // Add properties near the top, after existing private vars
    private var micRetryCount = 0
    private let maxMicRetries = 3
    
    // Add current interim transcripts per source
    private var currentInterim: [AudioSource: String] = [.mic: "", .system: ""]
    
    // Add ping timers to keep WebSocket connections alive
    private var pingTimers: [AudioSource: Timer] = [:]

    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                               object: audioEngine,
                                               queue: .main) { [weak self] _ in
            self?.handleAudioEngineConfigurationChange()
        }
        
        // Activate the process controller to start monitoring audio-producing apps
        audioProcessController.activate()
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
        
        // First ensure everything is stopped and cleaned up
        stopRecordingInternal()
        
        // Add a small delay to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Start microphone capture in parallel with system audio
            self.startMicrophoneTap()
            // Start system audio capture asynchronously
            Task {
                await self.startSystemAudioTap()
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
    
    private func startSystemAudioTap() async {
        print("🎧 Starting system audio tap...")
        
        // Ensure we have permission to record system audio. This might prompt the user.
        guard await checkSystemAudioPermissions() else {
            let errorMsg = "System audio recording permission denied."
            print("❌ \(errorMsg)")
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
            return
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
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
            return
        }
        
        self.processTap = newTap
        self.isTapActive = true
        
        // Start receiving audio data from the tap
        do {
            try startTapIO(newTap)
            connectToOpenAIRealtime(source: .system)
            print("✅ System audio tap started successfully")
            
            DispatchQueue.main.async {
                self.isRecording = true
                AudioLevelManager.shared.updateRecordingState(true)
            }
        } catch {
            let errorMsg = "Failed to start system audio tap IO: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            DispatchQueue.main.async {
                self.errorMessage = errorMsg
            }
            newTap.invalidate()
            self.isTapActive = false
        }
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
            print("Audio tap was invalidated.")
            DispatchQueue.main.async {
                self?.stopRecording()
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
    
    private func handleWebSocketError(_ error: Error, source: AudioSource) -> String {
        // Check for WebSocket close codes first
        if let closeCode = (error as NSError?)?.userInfo["closeCode"] as? Int {
            return ErrorHandler.shared.handleWebSocketCloseCode(closeCode)
        }
        
        // Use centralized error handler for all other errors
        return ErrorHandler.shared.handleError(error)
    }
    


    private func parseRealtimeEvent(_ text: String, source: AudioSource) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

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
