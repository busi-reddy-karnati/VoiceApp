//
//  VoiceNotesApp.swift
//  VoiceNotesApp
//
//  Main app entry point
//

import SwiftUI
import AVFoundation

@main
struct VoiceNotesApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(DataPersistenceService.shared)
                .environmentObject(PermissionsManager.shared)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Request initial permissions
        PermissionsManager.shared.checkAllPermissions()
        
        // Configure audio session
        do {
            try AVFoundation.AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker]
            )
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}

