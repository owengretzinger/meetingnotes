import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @State private var currentStep = 0
    @State private var apiKey = ""
    @State private var hasAcceptedTerms = false
    @State private var micPermissionGranted = false
    @State private var screenPermissionGranted = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    let totalSteps = 3
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Welcome to Meetingnotes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Let's get you set up in just a few steps")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Progress indicator
                    ProgressView(value: Double(currentStep), total: Double(totalSteps))
                        .frame(maxWidth: 300)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                
                // Content area
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            permissionsStep
                        case 1:
                            apiKeyStep
                        case 2:
                            termsStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: .infinity)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == totalSteps - 1 ? "Get Started" : "Next") {
                        if currentStep == totalSteps - 1 {
                            // Complete onboarding
                            settingsViewModel.settings.openAIKey = apiKey
                            settingsViewModel.completeOnboarding()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
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
    
    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Required Permissions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Meetingnotes needs these permissions to record and transcribe your meetings.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
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
                    Text("All permissions granted! You can proceed to the next step.")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var apiKeyStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("OpenAI API Key")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter your OpenAI API key to enable meeting transcription and note generation.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
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
    }
    
    private var termsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Terms and Privacy")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please review and accept our terms of service and privacy policy.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy Policy")
                            .font(.headline)
                        
                        Text("""
                        Meetingnotes respects your privacy. Here's what you should know:
                        
                        • All audio recordings and transcriptions are processed locally on your device
                        • Your OpenAI API key is stored securely in your device's keychain
                        • We do not collect, store, or transmit your meeting data to our servers
                        • Audio data is sent to OpenAI's API for transcription using your API key
                        • You can delete all data at any time through the app settings
                        
                        For the complete privacy policy, visit: https://meetingnotes.app/privacy
                        """)
                        .font(.body)
                        .foregroundColor(.primary)
                        
                        Text("Terms of Service")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        Text("""
                        By using Meetingnotes, you agree to:
                        
                        • Use the app responsibly and in accordance with applicable laws
                        • Respect the privacy and consent of meeting participants
                        • Comply with your organization's policies regarding recording meetings
                        • Not use the app for illegal or unauthorized purposes
                        
                        For the complete terms of service, visit: https://meetingnotes.app/terms
                        """)
                        .font(.body)
                        .foregroundColor(.primary)
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                
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
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return micPermissionGranted && screenPermissionGranted
        case 1:
            return !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return hasAcceptedTerms
        default:
            return false
        }
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