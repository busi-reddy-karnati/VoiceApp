//
//  MainView.swift
//  VoiceNotesApp
//
//  Main tab view container
//

import SwiftUI

/// Root view with tab navigation
struct MainView: View {
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            RecordingsListView()
                .tabItem {
                    Label("Recordings", systemImage: "list.bullet")
                }
        }
    }
}

#Preview {
    MainView()
}

