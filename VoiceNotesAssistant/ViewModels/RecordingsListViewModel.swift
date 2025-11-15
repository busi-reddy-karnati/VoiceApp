//
//  RecordingsListViewModel.swift
//  VoiceNotesApp
//
//  ViewModel for recordings list screen
//

import Foundation
import Combine

/// ViewModel managing the recordings list screen state and logic
@MainActor
class RecordingsListViewModel: ObservableObject {
    @Published var voiceNotes: [VoiceNote] = []
    @Published var groupedNotes: [DateGroup: [VoiceNote]] = [:]
    @Published var selectedNote: VoiceNote?
    @Published var showingDetailView = false
    @Published var totalStorageUsed: String = "0 KB"
    
    private let persistenceService = DataPersistenceService.shared
    private let audioPlaybackService = AudioPlaybackService()
    private let audioFileManager = AudioFileManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    enum DateGroup: Hashable, Comparable {
        case today
        case yesterday
        case date(Date)
        
        var displayName: String {
            switch self {
            case .today:
                return "Today"
            case .yesterday:
                return "Yesterday"
            case .date(let date):
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                return formatter.string(from: date)
            }
        }
        
        static func < (lhs: DateGroup, rhs: DateGroup) -> Bool {
            switch (lhs, rhs) {
            case (.today, .yesterday), (.today, .date), (.yesterday, .date):
                return true
            case (.yesterday, .today), (.date, .today), (.date, .yesterday):
                return false
            case (.date(let date1), .date(let date2)):
                return date1 > date2
            default:
                return false
            }
        }
    }
    
    init() {
        setupBindings()
        fetchNotes()
        calculateStorage()
    }
    
    private func setupBindings() {
        persistenceService.$voiceNotes
            .sink { [weak self] notes in
                self?.voiceNotes = notes
                self?.groupNotesByDate()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Fetches all voice notes
    func fetchNotes() {
        persistenceService.fetchVoiceNotes()
    }
    
    /// Deletes a voice note
    func deleteNote(_ note: VoiceNote) {
        persistenceService.deleteVoiceNote(note)
        calculateStorage()
    }
    
    /// Toggles playback for a note
    func togglePlayback(for note: VoiceNote) {
        guard let fileName = note.audioFileName else { return }
        
        do {
            try audioPlaybackService.togglePlayPause(fileName: fileName)
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }
    
    /// Checks if a note is currently playing
    func isPlaying(_ note: VoiceNote) -> Bool {
        return audioPlaybackService.currentlyPlayingFileName == note.audioFileName &&
               audioPlaybackService.isPlaying
    }
    
    /// Formats duration for display
    func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formats time for display
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Shows detail view for a note
    func showDetail(for note: VoiceNote) {
        selectedNote = note
        showingDetailView = true
    }
    
    /// Calculates total storage used
    func calculateStorage() {
        let bytes = audioFileManager.calculateTotalStorageUsed()
        totalStorageUsed = audioFileManager.formatStorageSize(bytes)
    }
    
    /// Gets the playback service for binding
    func getPlaybackService() -> AudioPlaybackService {
        return audioPlaybackService
    }
    
    // MARK: - Private Methods
    
    private func groupNotesByDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var grouped: [DateGroup: [VoiceNote]] = [:]
        
        for note in voiceNotes {
            guard let createdAt = note.createdAt else { continue }
            
            let noteDate = calendar.startOfDay(for: createdAt)
            let daysDifference = calendar.dateComponents([.day], from: noteDate, to: today).day ?? 0
            
            let group: DateGroup
            if daysDifference == 0 {
                group = .today
            } else if daysDifference == 1 {
                group = .yesterday
            } else {
                group = .date(noteDate)
            }
            
            grouped[group, default: []].append(note)
        }
        
        groupedNotes = grouped
    }
}

