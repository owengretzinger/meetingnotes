// AudioManager.swift
import AVFoundation
import Foundation
import SwiftUI
import ScreenCaptureKit

class AudioManager: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    
    private var stream: SCStream?
    private var webSocketTask: URLSessionWebSocketTask?
    private let deepgramURL = URL(string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=48000&channels=1&interim_results=true")!
    
    func startRecording() {
        // Check if ScreenCaptureKit is available
        guard #available(macOS 13.0, *) else {
            print("ScreenCaptureKit requires macOS 13.0 or later")
            return
        }
        
        Task {
            do {
                // Request permission for screen recording (includes system audio)
                let canRecord = await requestScreenRecordingPermission()
                if !canRecord {
                    print("Screen recording permission denied")
                    DispatchQueue.main.async {
                        self.isRecording = false
                    }
                    return
                }
                
                // Set up screen capture configuration
                let config = SCStreamConfiguration()
                config.capturesAudio = true
                config.captureMicrophone = true
                config.sampleRate = 48000
                config.channelCount = 1
                
                // Create content filter for desktop audio capture
                let availableContent = try await SCShareableContent.current
                guard let display = availableContent.displays.first else {
                    print("No displays available for capture")
                    DispatchQueue.main.async {
                        self.isRecording = false
                    }
                    return
                }
                let filter = SCContentFilter(display: display, excludingWindows: [])
                
                // Create stream
                stream = SCStream(filter: filter, configuration: config, delegate: self)
                
                // Add audio output
                try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "AudioQueue"))
                try stream?.addStreamOutput(self, type: .microphone, sampleHandlerQueue: DispatchQueue(label: "MicQueue"))
                
                // Start capture
                try await stream?.startCapture()
                
                DispatchQueue.main.async {
                    self.isRecording = true
                }
                
                // Connect to Deepgram
                connectToDeepgram()
                
            } catch {
                print("Failed to start recording: \(error)")
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
    }
    
    func stopRecording() {
        Task {
            do {
                try await stream?.stopCapture()
                stream = nil
                webSocketTask?.cancel(with: .normalClosure, reason: nil)
                webSocketTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            } catch {
                print("Failed to stop recording: \(error)")
            }
        }
    }
    
    private func requestScreenRecordingPermission() async -> Bool {
        // ScreenCaptureKit handles permission requests automatically
        // This will show a system dialog if needed
        do {
            let _ = try await SCShareableContent.current
            return true
        } catch {
            return false
        }
    }
    
    private func connectToDeepgram() {
        let session = URLSession(configuration: .default)
        var request = URLRequest(url: deepgramURL)
        if let key = KeychainHelper.shared.get(forKey: "deepgramKey"), !key.isEmpty {
            request.addValue("Token \(key)", forHTTPHeaderField: "Authorization")
        } else {
            print("No Deepgram key found")
            return
        }
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func sendAudioData(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("Send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.parseTranscription(text)
                case .data:
                    break
                @unknown default:
                    break
                }
                self.receiveMessage() // Continue receiving
            case .failure(let error):
                print("Receive error: \(error)")
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
extension AudioManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

// MARK: - SCStreamOutput
extension AudioManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Convert sample buffer to audio data and send to Deepgram
        guard let audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { 
            print("Failed to get data buffer from sample buffer")
            return 
        }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(audioBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        guard status == noErr, let pointer = dataPointer, length > 0 else { 
            print("Failed to get audio data pointer, status: \(status), length: \(length)")
            return 
        }
        
        let data = Data(bytes: pointer, count: length)
        sendAudioData(data)
    }
} 