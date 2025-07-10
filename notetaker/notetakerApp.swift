//
//  notetakerApp.swift
//  notetaker
//
//  Created by Owen Gretzinger on 2025-07-10.
//

import SwiftUI

@main
struct notetakerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
