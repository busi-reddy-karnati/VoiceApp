//
//  AudioRecordingService.swift
//  VoiceNotesApp
//
//  Manages audio recording with high-quality AAC format
//

import AVFoundation
import Combine

/// Service responsible for audio recording functionality
class AudioRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var error: AudioRecordingError?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var maxRecordingDuration: TimeInterval = 120.0 // 2 minutes
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    enum AudioRecordingError: LocalizedError {
        case permissionDenied
        case recordingFailed
        case audioSessionSetupFailed
        case maxDurationReached
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Microphone permission is required to record audio."
            case .recordingFailed:
                return "Failed to start recording. Please try again."
            case .audioSessionSetupFailed:
                return "Failed to setup audio session."
            case .maxDurationReached:
                return "Maximum recording duration of 2 minutes reached."
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    /// Starts recording audio
    func startRecording() async throws -> URL {
        // Request permission if needed
        guard await PermissionsManager.shared.requestMicrophonePermission() else {
            throw AudioRecordingError.permissionDenied
        }
        
        // Setup audio session
        try setupAudioSession()
        
        // Generate file URL
        let audioURL = AudioFileManager.shared.generateAudioFileURL()
        
        // Configure recording settings for high-quality AAC
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        
        // Start recording
        guard audioRecorder?.record() == true else {
            throw AudioRecordingError.recordingFailed
        }
        
        await MainActor.run {
            isRecording = true
            recordingDuration = 0
            startTimers()
        }
        
        return audioURL
    }
    
    /// Stops recording and returns the final duration
    func stopRecording() async -> TimeInterval {
        let duration = recordingDuration
        
        await MainActor.run {
            isRecording = false
        }
        
        audioRecorder?.stop()
        stopTimers()
        
        await MainActor.run {
            recordingDuration = 0
            audioLevel = 0
        }
        
        return duration
    }
    
    /// Cancels recording and deletes the file
    func cancelRecording() async {
        guard let url = audioRecorder?.url else { return }
        
        await MainActor.run {
            isRecording = false
        }
        
        audioRecorder?.stop()
        stopTimers()
        
        // Delete the file
        try? FileManager.default.removeItem(at: url)
        
        await MainActor.run {
            recordingDuration = 0
            audioLevel = 0
        }
    }
    
    /// Pauses recording
    func pauseRecording() {
        audioRecorder?.pause()
        stopTimers()
    }
    
    /// Resumes recording
    func resumeRecording() {
        audioRecorder?.record()
        startTimers()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() throws {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            throw AudioRecordingError.audioSessionSetupFailed
        }
    }
    
    private func startTimers() {
        // Duration timer (updates every 0.1 seconds)
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Only update if still recording
                guard self.isRecording else { return }
                
                self.recordingDuration += 0.1
                
                // Check if max duration reached
                if self.recordingDuration >= self.maxRecordingDuration {
                    self.error = .maxDurationReached
                    _ = await self.stopRecording()
                }
            }
        }
        
        // Audio level timer (updates every 0.05 seconds for smooth animation)
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Only update if still recording
                guard self.isRecording, let recorder = self.audioRecorder else { return }
                
                recorder.updateMeters()
                let averagePower = recorder.averagePower(forChannel: 0)
                
                // Convert to 0-1 range for visualization
                let normalizedLevel = self.normalizeAudioLevel(averagePower)
                self.audioLevel = normalizedLevel
            }
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    /// Normalizes audio level from dB to 0-1 range
    private func normalizeAudioLevel(_ power: Float) -> Float {
        // power ranges from -160 to 0 dB
        let minDb: Float = -60
        let maxDb: Float = 0
        
        let clampedPower = max(minDb, min(maxDb, power))
        return (clampedPower - minDb) / (maxDb - minDb)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                self.error = .recordingFailed
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.error = .recordingFailed
        }
    }
}

