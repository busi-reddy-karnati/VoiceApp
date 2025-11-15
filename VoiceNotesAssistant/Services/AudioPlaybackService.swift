//
//  AudioPlaybackService.swift
//  VoiceNotesApp
//
//  Manages audio playback for recorded voice notes
//

import AVFoundation
import Combine

/// Service responsible for audio playback functionality
@MainActor
class AudioPlaybackService: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentlyPlayingFileName: String?
    @Published var playbackProgress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    
    override init() {
        super.init()
    }
    
    /// Plays an audio file
    func play(fileName: String) throws {
        // Stop current playback if any
        stop()
        
        // Get file URL
        let fileURL = AudioFileManager.shared.audioFileURL(for: fileName)
        
        // Create player
        audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        // Start playing
        audioPlayer?.play()
        
        isPlaying = true
        currentlyPlayingFileName = fileName
        duration = audioPlayer?.duration ?? 0
        
        startProgressTimer()
    }
    
    /// Pauses playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    /// Resumes playback
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    /// Stops playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingFileName = nil
        playbackProgress = 0
        currentTime = 0
        duration = 0
        stopProgressTimer()
    }
    
    /// Seeks to a specific time
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateProgress()
    }
    
    /// Toggles play/pause for a specific file
    func togglePlayPause(fileName: String) throws {
        if currentlyPlayingFileName == fileName && isPlaying {
            pause()
        } else if currentlyPlayingFileName == fileName && !isPlaying {
            resume()
        } else {
            try play(fileName: fileName)
        }
    }
    
    // MARK: - Private Methods
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        
        if duration > 0 {
            playbackProgress = currentTime / duration
        }
    }
    
    private func handlePlaybackFinished() {
        isPlaying = false
        currentlyPlayingFileName = nil
        playbackProgress = 0
        currentTime = 0
        stopProgressTimer()
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.handlePlaybackFinished()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.stop()
        }
    }
}

