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
    // Initialize Core Data persistence
    @StateObject private var persistenceService = DataPersistenceService.shared
    @StateObject private var permissionsManager = PermissionsManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(persistenceService)
                .environmentObject(permissionsManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Request initial permissions
        permissionsManager.checkAllPermissions()
        
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

