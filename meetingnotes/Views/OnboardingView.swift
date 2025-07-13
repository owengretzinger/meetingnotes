import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var apiKey = ""
    @State private var hasAcceptedTerms = false
    @State private var micPermissionGranted = false
    @State private var screenPermissionGranted = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Welcome to Meetingnotes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Let's get you set up to start transcribing meetings")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                
                // Content area
                ScrollView {
                    VStack(spacing: 32) {
                        // Permissions Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Required Permissions")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Meetingnotes needs these permissions to record and transcribe your meetings.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 12) {
                                PermissionRow(
                                    title: "Microphone Access",
                                    description: "Required to capture audio from your meetings",
                                    isGranted: micPermissionGranted,
                                    action: requestMicrophonePermission
                                )
                                
                                PermissionRow(
                                    title: "Screen Recording",
                                    description: "Required to capture system audio for transcription",
                                    isGranted: screenPermissionGranted,
                                    action: requestScreenPermission
                                )
                            }
                            
                            if micPermissionGranted && screenPermissionGranted {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("All permissions granted!")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // API Key Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OpenAI API Key")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Enter your OpenAI API key to enable meeting transcription and note generation.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                SecureField("OpenAI API Key", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body)
                                
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.blue)
                                    Text("Your API key is stored securely and encrypted locally.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Get API Key from OpenAI") {
                                    if let url = URL(string: "https://platform.openai.com/api-keys") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.link)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Terms Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms and Privacy")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Please review and accept our terms of service and privacy policy.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button("Privacy Policy") {
                                        if let url = URL(string: "https://meetingnotes.app/privacy") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.link)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Button("Terms of Service") {
                                        if let url = URL(string: "https://meetingnotes.app/terms") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.link)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Button(action: { hasAcceptedTerms.toggle() }) {
                                        Image(systemName: hasAcceptedTerms ? "checkmark.square.fill" : "square")
                                            .foregroundColor(hasAcceptedTerms ? .blue : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("I have read and agree to the Terms of Service and Privacy Policy")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                
                // Get Started Button
                VStack {
                    Button("Get Started") {
                        // Complete onboarding
                        settingsViewModel.settings.openAIKey = apiKey
                        settingsViewModel.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canProceed)
                    
                    if !canProceed {
                        Text("Please complete all steps above to continue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK") { }
        } message: {
            Text(permissionAlertMessage)
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    private var canProceed: Bool {
        return micPermissionGranted && 
               screenPermissionGranted && 
               !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               hasAcceptedTerms
    }
    
    private func checkPermissions() {
        // Check microphone permission
        micPermissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        
        // Check screen recording permission (this is more complex on macOS)
        screenPermissionGranted = CGPreflightScreenCaptureAccess()
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                micPermissionGranted = granted
                if !granted {
                    permissionAlertMessage = "Microphone access is required for recording meetings. Please enable it in System Preferences > Security & Privacy > Privacy > Microphone."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func requestScreenPermission() {
        let success = CGRequestScreenCaptureAccess()
        DispatchQueue.main.async {
            screenPermissionGranted = success
            if !success {
                permissionAlertMessage = "Screen recording access is required to capture system audio. Please enable it in System Preferences > Security & Privacy > Privacy > Screen Recording."
                showingPermissionAlert = true
            }
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingView(settingsViewModel: SettingsViewModel())
        .frame(width: 600, height: 700)
}