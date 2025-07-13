//
//  ContentView.swift
//  meetingnotes
//
//  Created by Owen Gretzinger on 2025-07-10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            if !settingsViewModel.settings.hasCompletedOnboarding {
                OnboardingView(settingsViewModel: settingsViewModel)
            } else {
                MeetingListView(settingsViewModel: settingsViewModel)
            }
        }
        .onAppear {
            // Force load settings to check onboarding status
            settingsViewModel.loadSettings()
        }
    }
}

#Preview {
    ContentView()
}
