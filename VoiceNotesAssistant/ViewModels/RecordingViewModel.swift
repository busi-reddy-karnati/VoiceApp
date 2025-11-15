//
//  RecordingViewModel.swift
//  VoiceNotesApp
//
//  ViewModel for recording screen
//

import Foundation
import Combine

/// ViewModel managing the recording screen state and logic
@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var locationData: LocationData?
    @Published var showingSaveAlert = false
    @Published var showingPermissionAlert = false
    @Published var permissionAlertMessage = ""
    @Published var isTranscribing = false
    @Published var showingMaxDurationWarning = false
    
    private let audioRecordingService = AudioRecordingService()
    private let locationService = LocationService()
    private let transcriptionService = TranscriptionService()
    private let persistenceService = DataPersistenceService.shared
    
    private var currentRecordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind audio recording service properties
        audioRecordingService.$isRecording
            .assign(to: &$isRecording)
        
        audioRecordingService.$recordingDuration
            .sink { [weak self] duration in
                self?.recordingDuration = duration
                // Show warning at 90 seconds
                if duration >= 90 && duration < 91 {
                    self?.showingMaxDurationWarning = true
                }
            }
            .store(in: &cancellables)
        
        audioRecordingService.$audioLevel
            .assign(to: &$audioLevel)
        
        // Handle recording errors
        audioRecordingService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleRecordingError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Starts a new recording
    func startRecording() async {
        do {
            // Capture location
            locationData = await locationService.captureLocation()
            
            // Start recording
            currentRecordingURL = try await audioRecordingService.startRecording()
            
        } catch {
            permissionAlertMessage = error.localizedDescription
            showingPermissionAlert = true
        }
    }
    
    /// Stops the current recording
    func stopRecording() async {
        guard let recordingURL = currentRecordingURL else { return }
        
        let duration = await audioRecordingService.stopRecording()
        
        // Save to Core Data
        let fileName = recordingURL.lastPathComponent
        let voiceNote = persistenceService.createVoiceNote(
            audioFileName: fileName,
            duration: duration,
            locationData: locationData
        )
        
        // Show save confirmation
        showingSaveAlert = true
        
        // Start transcription in background
        Task {
            await transcribeRecording(voiceNote: voiceNote, audioURL: recordingURL)
        }
        
        // Reset state
        currentRecordingURL = nil
        locationData = nil
        showingMaxDurationWarning = false
    }
    
    /// Cancels the current recording
    func cancelRecording() async {
        await audioRecordingService.cancelRecording()
        currentRecordingURL = nil
        locationData = nil
        showingMaxDurationWarning = false
    }
    
    /// Pauses recording
    func pauseRecording() {
        audioRecordingService.pauseRecording()
        isPaused = true
    }
    
    /// Resumes recording
    func resumeRecording() {
        audioRecordingService.resumeRecording()
        isPaused = false
    }
    
    /// Formats duration for display
    func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Methods
    
    private func transcribeRecording(voiceNote: VoiceNote, audioURL: URL) async {
        isTranscribing = true
        
        do {
            let transcript = try await transcriptionService.transcribe(audioFileURL: audioURL)
            persistenceService.updateTranscription(voiceNote: voiceNote, transcript: transcript)
        } catch {
            print("Transcription failed: \(error.localizedDescription)")
            // Update status even if transcription fails
            persistenceService.updateTranscribingStatus(voiceNote: voiceNote, isTranscribing: false)
        }
        
        isTranscribing = false
    }
    
    private func handleRecordingError(_ error: AudioRecordingService.AudioRecordingError) {
        if case .maxDurationReached = error {
            // Auto-stop triggered
            Task {
                await stopRecording()
            }
        }
    }
}

