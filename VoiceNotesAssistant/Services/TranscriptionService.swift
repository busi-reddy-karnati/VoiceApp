//
//  TranscriptionService.swift
//  VoiceNotesApp
//
//  Manages local speech recognition and transcription
//

import AVFoundation
import Combine
import Speech

/// Service responsible for transcribing audio recordings
class TranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    enum TranscriptionError: LocalizedError {
        case permissionDenied
        case recognizerNotAvailable
        case transcriptionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Speech recognition permission is required for transcription."
            case .recognizerNotAvailable:
                return "Speech recognizer is not available."
            case .transcriptionFailed(let reason):
                return "Transcription failed: \(reason)"
            }
        }
    }
    
    /// Transcribes an audio file
    func transcribe(audioFileURL: URL) async throws -> String {
        // Request permission if needed
        guard await requestPermissionIfNeeded() else {
            throw TranscriptionError.permissionDenied
        }
        
        // Check if recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerNotAvailable
        }
        
        await MainActor.run {
            isTranscribing = true
        }
        
        defer {
            Task { @MainActor in
                isTranscribing = false
            }
        }
        
        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = true // Force local processing
        
        // Perform recognition
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: TranscriptionError.transcriptionFailed("No result received"))
                    return
                }
                
                if result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                    continuation.resume(returning: transcript)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func requestPermissionIfNeeded() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await PermissionsManager.shared.requestSpeechRecognitionPermission()
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

