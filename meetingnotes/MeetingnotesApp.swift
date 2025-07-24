//
//  meetingnotesApp.swift
//  meetingnotes
//
//  Created by Owen Gretzinger on 2025-07-10.
//

import SwiftUI
import Sparkle
import PostHog

@main
struct MeetingnotesApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(updaterDelegate: nil, userDriverDelegate: nil)
        // Setup PostHog analytics for anonymous tracking
        let posthogAPIKey = "phc_Wt8sWUzUF7YPF50aQ0B1qbfA5SJWWR341zmXCaIaIRJ"
        let posthogHost = "https://us.i.posthog.com"
        let config = PostHogConfig(apiKey: posthogAPIKey, host: posthogHost)
        // Only capture anonymous events
        config.personProfiles = .never
        // Enable lifecycle and screen view autocapture
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = true
        PostHogSDK.shared.setup(config)
        // Register environment as a super property
        #if DEBUG
        PostHogSDK.shared.register(["environment": "dev"] )
        #else
        PostHogSDK.shared.register(["environment": "prod"] )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
            // Hidden command group that handles audio level window notifications
            CommandGroup(after: .windowArrangement) {
                ShowAudioLevelsCommand()
            }
        }
        
        // Floating Audio Level Window
        Window("", id: "audio-levels") {
            AudioLevelWindowView()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultPosition(.trailing)
    }
}

struct CheckForUpdatesView: View {
    let updater: SPUUpdater

    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .keyboardShortcut("u", modifiers: .command)
    }
}

struct ShowAudioLevelsCommand: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        // Empty view - we only need this for the notification observer
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: .openAudioLevelWindow)) { _ in
                openWindow(id: "audio-levels")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    AudioLevelWindowManager.shared.showWindow()
                }
            }
    }
}
