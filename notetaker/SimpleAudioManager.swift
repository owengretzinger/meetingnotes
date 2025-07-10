// SimpleAudioManager.swift
// Audio manager for microphone and system audio capture

import AVFoundation
import Foundation
import SwiftUI
import ScreenCaptureKit

class SimpleAudioManager: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var captureSystemAudio = true
    
    private var audioEngine = AVAudioEngine()
    private var systemAudioEngine = AVAudioEngine()
    private var webSocketTask: URLSessionWebSocketTask?
    private let deepgramURL = URL(string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=16000&channels=1&interim_results=true")!
    
    // ScreenCaptureKit properties
    private var stream: SCStream?
    private var streamConfiguration: SCStreamConfiguration?
    
    func startRecording() {
        print("Starting recording...")
        
        if captureSystemAudio {
            startSystemAudioCapture()
        } else {
            startMicrophoneOnly()
        }
    }
    
    private func startMicrophoneOnly() {
        print("Starting microphone-only recording...")
        
        // Set up audio engine for microphone capture
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Convert to the format Deepgram expects: 16kHz, 16-bit, mono
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                       sampleRate: 16000, 
                                       channels: 1, 
                                       interleaved: false)!
        
        let converter = AVAudioConverter(from: recordingFormat, to: targetFormat)!
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
            connectToDeepgram()
            print("Microphone recording started")
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func startSystemAudioCapture() {
        print("Starting system audio capture...")
        
        Task {
            do {
                // Request screen recording permission
                let canRecord = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                
                // Get the main display
                guard let display = canRecord.displays.first else {
                    print("❌ No display found")
                    return
                }
                
                // Configure stream for audio only
                let configuration = SCStreamConfiguration()
                configuration.capturesAudio = true
                configuration.excludesCurrentProcessAudio = false
                configuration.sampleRate = 16000
                configuration.channelCount = 1
                
                // Create content filter (we only want audio, but need to include display)
                let filter = SCContentFilter(display: display, excludingWindows: [])
                
                // Create and start stream
                let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
                
                try await stream.startCapture()
                
                self.stream = stream
                self.streamConfiguration = configuration
                
                DispatchQueue.main.async {
                    self.isRecording = true
                }
                
                connectToDeepgram()
                print("System audio capture started")
                
            } catch {
                print("❌ Failed to start system audio capture: \(error)")
                // Fallback to microphone only
                startMicrophoneOnly()
            }
        }
    }
    
    func stopRecording() {
        print("Stopping recording...")
        
        // Stop system audio capture
        if let stream = stream {
            Task {
                try? await stream.stopCapture()
            }
            self.stream = nil
        }
        
        // Stop microphone capture
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Close WebSocket
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        print("Recording stopped")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) {
        // Create output buffer for conversion
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            print("❌ Failed to create output buffer")
            return
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard status == .haveData, error == nil else {
            print("❌ Audio conversion failed: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        // Convert to Data for Deepgram
        guard let channelData = outputBuffer.int16ChannelData?[0] else {
            print("❌ No channel data available")
            return
        }
        
        let frameCount = Int(outputBuffer.frameLength)
        let data = Data(bytes: channelData, count: frameCount * 2)
        
        print("🎵 Sending audio data: \(data.count) bytes")
        sendAudioData(data)
    }
    
    private func connectToDeepgram() {
        guard let key = KeychainHelper.shared.get(forKey: "deepgramKey"), !key.isEmpty else {
            print("❌ No Deepgram key found")
            return
        }
        
        print("🔑 Using Deepgram key: \(String(key.prefix(8)))...")
        
        let session = URLSession(configuration: .default)
        var request = URLRequest(url: deepgramURL)
        request.addValue("Token \(key)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
        print("🌐 Attempting to connect to Deepgram...")
    }
    
    private func sendAudioData(_ data: Data) {
        guard webSocketTask?.state == .running else {
            print("⚠️ WebSocket not connected, skipping audio data")
            return
        }
        
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("❌ Send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📝 Received: \(text)")
                    self?.parseTranscription(text)
                case .data:
                    break
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving
            case .failure(let error):
                print("❌ Receive error: \(error)")
                // Try to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self?.isRecording == true {
                        print("🔄 Attempting to reconnect...")
                        self?.connectToDeepgram()
                    }
                }
            }
        }
    }
    
    private func parseTranscription(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String, type == "Results",
              let channel = json["channel"] as? [String: Any],
              let alternatives = channel["alternatives"] as? [[String: Any]],
              let alt = alternatives.first,
              let transcript = alt["transcript"] as? String,
              !transcript.isEmpty else { return }
        
        DispatchQueue.main.async {
            if let isFinal = json["is_final"] as? Bool, isFinal {
                self.transcript += transcript + " "
            }
        }
    }
}

// MARK: - SCStreamDelegate
extension SimpleAudioManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        
        // Convert CMSampleBuffer to AVAudioPCMBuffer
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        
        guard let audioStreamBasicDescription = audioStreamBasicDescription else { return }
        
        let format = AVAudioFormat(streamDescription: audioStreamBasicDescription)
        guard let format = format else { return }
        
        let frameCount = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        
        // Copy audio data
        var blockBuffer: CMBlockBuffer?
        var audioBufferListOut = AudioBufferList()
        var audioBufferListSize = MemoryLayout<AudioBufferList>.size
        
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &audioBufferListSize,
            bufferListOut: &audioBufferListOut,
            bufferListSize: audioBufferListSize,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == noErr else { return }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Convert to target format and send
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                       sampleRate: 16000, 
                                       channels: 1, 
                                       interleaved: false)!
        
        let converter = AVAudioConverter(from: format, to: targetFormat)!
        processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ Stream stopped with error: \(error)")
    }
} 