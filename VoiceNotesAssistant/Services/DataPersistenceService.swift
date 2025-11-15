//
//  DataPersistenceService.swift
//  VoiceNotesApp
//
//  Manages Core Data persistence for voice notes
//

import CoreData
import Foundation

/// Service responsible for Core Data operations
class DataPersistenceService: ObservableObject {
    static let shared = DataPersistenceService()
    
    let container: NSPersistentContainer
    
    @Published var voiceNotes: [VoiceNote] = []
    
    init() {
        container = NSPersistentContainer(name: "VoiceNote")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        fetchVoiceNotes()
    }
    
    /// Fetches all voice notes sorted by creation date
    func fetchVoiceNotes() {
        let request = NSFetchRequest<VoiceNote>(entityName: "VoiceNote")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VoiceNote.createdAt, ascending: false)]
        
        do {
            voiceNotes = try container.viewContext.fetch(request)
        } catch {
            print("Failed to fetch voice notes: \(error.localizedDescription)")
        }
    }
    
    /// Creates a new voice note
    func createVoiceNote(
        audioFileName: String,
        duration: TimeInterval,
        locationData: LocationData?
    ) -> VoiceNote {
        let context = container.viewContext
        let voiceNote = VoiceNote(context: context)
        
        voiceNote.id = UUID()
        voiceNote.createdAt = Date()
        voiceNote.audioFileName = audioFileName
        voiceNote.duration = duration
        voiceNote.isTranscribing = true
        
        // Location data
        if let locationData = locationData {
            voiceNote.latitude = locationData.latitude
            voiceNote.longitude = locationData.longitude
            voiceNote.placeName = locationData.placeName
            voiceNote.address = locationData.address
        } else {
            voiceNote.latitude = 0
            voiceNote.longitude = 0
        }
        
        // V1 prep fields with defaults
        voiceNote.heartRate = 0
        voiceNote.heartRateVariability = 0
        voiceNote.respiratoryRate = 0
        voiceNote.moodScore = 0
        
        save()
        fetchVoiceNotes()
        
        return voiceNote
    }
    
    /// Updates a voice note with transcription
    func updateTranscription(voiceNote: VoiceNote, transcript: String) {
        voiceNote.transcript = transcript
        voiceNote.isTranscribing = false
        save()
        fetchVoiceNotes()
    }
    
    /// Updates transcription status
    func updateTranscribingStatus(voiceNote: VoiceNote, isTranscribing: Bool) {
        voiceNote.isTranscribing = isTranscribing
        save()
        fetchVoiceNotes()
    }
    
    /// Deletes a voice note
    func deleteVoiceNote(_ voiceNote: VoiceNote) {
        // Delete audio file
        try? AudioFileManager.shared.deleteAudioFile(fileName: voiceNote.audioFileName ?? "")
        
        // Delete from Core Data
        container.viewContext.delete(voiceNote)
        save()
        fetchVoiceNotes()
    }
    
    /// Saves the context
    private func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
}

