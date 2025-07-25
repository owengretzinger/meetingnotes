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
                .frame(minWidth: 700, minHeight: 400)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 600)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
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
