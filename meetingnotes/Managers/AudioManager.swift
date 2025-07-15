// AudioManager.swift
// Unified audio manager for microphone and system audio capture

import AVFoundation
import Foundation
import SwiftUI
import ScreenCaptureKit

/// Manages audio capture from microphone and system audio and handles real-time transcription via OpenAI
class AudioManager: NSObject, ObservableObject {
    @Published var transcriptChunks: [TranscriptChunk] = []
    @Published var isRecording = false
    
    private var audioEngine = AVAudioEngine()
    private var micSocketTask: URLSessionWebSocketTask?
    private var systemSocketTask: URLSessionWebSocketTask?
    private let realtimeURL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
    
    // ScreenCaptureKit properties
    private var stream: SCStream?
    
    // Add properties near the top, after existing private vars
    private var micRetryCount = 0
    private let maxMicRetries = 3
    
    // Add current interim transcripts per source
    private var currentInterim: [AudioSource: String] = [.mic: "", .system: ""]

    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                               object: audioEngine,
                                               queue: .main) { [weak self] _ in
            self?.handleAudioEngineConfigurationChange()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startRecording() {
        print("Starting recording...")
        
        // First ensure everything is stopped and cleaned up
        stopRecordingInternal()
        
        // Add a small delay to ensure cleanup is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Start microphone capture in parallel with system audio
            self.startMicrophoneTap()
            // Start system audio capture asynchronously
            Task {
                await self.startSystemAudioCapture()
            }
        }
    }
    
    private func stopRecordingInternal() {
        print("Internal cleanup...")
        
        // Stop system audio capture
        if let stream = stream {
            stream.stopCapture()
            self.stream = nil
            print("System audio capture stopped")
        }
        
        // Stop microphone capture
        cleanupAudioEngine()
        
        // Close WebSocket
        micSocketTask?.cancel(with: .normalClosure, reason: nil)
        micSocketTask = nil
        systemSocketTask?.cancel(with: .normalClosure, reason: nil)
        systemSocketTask = nil
        
        // Reset state
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
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
                
                // Debug mic RMS
                if let ch = buffer.floatChannelData?[0] {
                    let frameCount = Int(buffer.frameLength)
                    let samples = UnsafeBufferPointer(start: ch, count: frameCount)
                    let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameCount))
                    print("🎤 Mic RMS: \(rms)")
                    
                    // Optional: Check for prolonged silence (e.g., RMS < threshold for multiple buffers)
                    // But for now, just process
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
    
    private func startSystemAudioCapture() async {
        print("🎧 Starting system audio capture...")
        
        do {
            // Request screen capture permission
            let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
            
            // Exclude self to avoid feedback
            let excludedApps = content.applications.filter { app in
                Bundle.main.bundleIdentifier == app.bundleIdentifier
            }
            
            guard let display = content.displays.first else {
                print("❌ No display found")
                return
            }
            
            // Create filter
            let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
            
            // Configure stream
            let configuration = SCStreamConfiguration()
            configuration.width = 2  // Minimal video settings
            configuration.height = 2
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale.max)
            configuration.capturesAudio = true
            configuration.sampleRate = 48000
            configuration.channelCount = 2
            
            // Create stream
            let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
            
            // Add stream output for audio processing
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
            // Add a minimal screen output so SCStream doesn't complain about missing video output
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
            
            // Start capture
            try await stream.startCapture()
            
            // Store reference
            self.stream = stream
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
            
            connectToOpenAIRealtime(source: .system)
            print("✅ System audio capture started successfully")
            
        } catch {
            print("❌ Failed to start system audio capture: \(error)")
            
            if case SCStreamError.userDeclined = error {
                print("📍 Permission denied. User needs to enable screen recording in System Settings.")
            }
        }
    }
    
    func stopRecording() {
        print("Stopping recording...")
        
        // Stop system audio capture
        if let stream = stream {
            stream.stopCapture()
            self.stream = nil
        }
        
        // Stop microphone capture
        cleanupAudioEngine()
        micRetryCount = 0
        
        // Close WebSocket
        micSocketTask?.cancel(with: .normalClosure, reason: nil)
        micSocketTask = nil
        systemSocketTask?.cancel(with: .normalClosure, reason: nil)
        systemSocketTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
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
            print("❌ No OpenAI key found")
            return
        }

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: realtimeURL)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let task = session.webSocketTask(with: request)
        task.resume()

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
                task.send(.string(jsonStr)) { error in
                    if let error = error {
                        print("❌ Config send error: \(error)")
                    }
                }
            }
        } catch {
            print("❌ Config JSON error: \(error)")
        }

        switch source {
        case .mic:
            micSocketTask = task
        case .system:
            systemSocketTask = task
        }

        receiveMessage(for: source)
        print("🌐 Connected to OpenAI Realtime (\(source))")
    }

    private func receiveMessage(for source: AudioSource) {
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
                self?.receiveMessage(for: source) // continue loop
            case .failure(let error):
                print("❌ Receive error (\(source)): \(error)")
                // Attempt reconnect if still recording
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self?.isRecording == true {
                        self?.connectToOpenAIRealtime(source: source)
                    }
                }
            }
        }
    }

    private func parseRealtimeEvent(_ text: String, source: AudioSource) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "conversation.item.input_audio_transcription.delta":
            if let delta = json["delta"] as? String {
                DispatchQueue.main.async {
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
                DispatchQueue.main.async {
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

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            if let jsonStr = String(data: jsonData, encoding: .utf8) {
                socket.send(.string(jsonStr)) { error in
                    if let error = error {
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

// MARK: - SCStreamDelegate & SCStreamOutput
extension AudioManager: SCStreamDelegate, SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard sampleBuffer.isValid else { return }
        
        // Convert CMSampleBuffer to AVAudioPCMBuffer
        guard let pcmBuffer = sampleBuffer.asPCMBuffer else { return }
        
        // Create converter for OpenAI format
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                       sampleRate: 24000,
                                       channels: 1,
                                       interleaved: false)!
        
        guard let converter = AVAudioConverter(from: pcmBuffer.format, to: targetFormat) else { return }
        
        processAudioBuffer(pcmBuffer, converter: converter, targetFormat: targetFormat, source: .system)
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped with error: \(error)")
        DispatchQueue.main.async {
            self.stream = nil
            self.isRecording = false
        }
    }
}

// MARK: - CMSampleBuffer Extension
extension CMSampleBuffer {
    var asPCMBuffer: AVAudioPCMBuffer? {
        try? self.withAudioBufferList { audioBufferList, _ -> AVAudioPCMBuffer? in
            guard let absd = self.formatDescription?.audioStreamBasicDescription else { return nil }
            guard let format = AVAudioFormat(standardFormatWithSampleRate: absd.mSampleRate, channels: absd.mChannelsPerFrame) else { return nil }
            return AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: audioBufferList.unsafePointer)
        }
    }
} 
