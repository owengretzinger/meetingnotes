//
//  ContentView.swift
//  notetaker
//
//  Created by Owen Gretzinger on 2025-07-10.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false
    
    var body: some View {
        MeetingListView()
    }
}

#Preview {
    ContentView()
}
