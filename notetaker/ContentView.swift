//
//  ContentView.swift
//  notetaker
//
//  Created by Owen Gretzinger on 2025-07-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = SimpleAudioManager()
    @State private var deepgramKey = ""
    @State private var openAIKey = ""
    @State private var userBlurb = ""
    @State private var systemPrompt = "Generate meeting notes from transcript and notes."

    var body: some View {
        VStack(spacing: 20) {
            Text("Notetaker Settings")
                .font(.title)
            
            TextField("Deepgram API Key", text: $deepgramKey)
            TextField("OpenAI API Key", text: $openAIKey)
            TextField("About Yourself (for prompt)", text: $userBlurb)
            TextEditor(text: $systemPrompt)
                .frame(height: 100)
            
            Button("Save") {
                saveSettings()
            }
            
            Divider()
            
            Toggle("Capture System Audio", isOn: $audioManager.captureSystemAudio)
                .disabled(audioManager.isRecording)
            
            HStack {
                Button("Start Recording") {
                    audioManager.startRecording()
                }
                .disabled(audioManager.isRecording)
                
                Button("Stop Recording") {
                    audioManager.stopRecording()
                }
                .disabled(!audioManager.isRecording)
            }
            
            if audioManager.isRecording {
                Text(audioManager.captureSystemAudio ? "🔴 Recording microphone + system audio..." : "🔴 Recording microphone...")
                    .foregroundColor(.red)
            }
            
            Text("Live Transcript:")
                .font(.headline)
            
            ScrollView {
                Text(audioManager.transcript.isEmpty ? "No transcript yet..." : audioManager.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 150)
            .border(Color.gray)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            loadSettings()
        }
    }
    
    func saveSettings() {
        _ = KeychainHelper.shared.save(deepgramKey, forKey: "deepgramKey")
        _ = KeychainHelper.shared.save(openAIKey, forKey: "openAIKey")
        _ = KeychainHelper.shared.save(userBlurb, forKey: "userBlurb")
        _ = KeychainHelper.shared.save(systemPrompt, forKey: "systemPrompt")
        print("Settings saved!")
    }

    private func loadSettings() {
        deepgramKey = KeychainHelper.shared.get(forKey: "deepgramKey") ?? ""
        openAIKey = KeychainHelper.shared.get(forKey: "openAIKey") ?? ""
        userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? "Generate meeting notes from transcript and notes."
    }
}

#Preview {
    ContentView()
}
