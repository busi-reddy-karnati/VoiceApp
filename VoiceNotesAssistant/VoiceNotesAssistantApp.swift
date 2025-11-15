//
//  VoiceNotesAssistantApp.swift
//  VoiceNotesAssistant
//
//  Created by Busi Reddy Karnati on 11/15/25.
//

import SwiftUI
import CoreData

@main
struct VoiceNotesAssistantApp: App {
    @StateObject private var dataPersistenceService = DataPersistenceService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataPersistenceService.container.viewContext)
                .environmentObject(dataPersistenceService)
        }
    }
}
