//
//  AudioFileManager.swift
//  VoiceNotesApp
//
//  Manages audio file storage and retrieval
//

import Foundation

/// Manages audio file operations including storage, retrieval, and deletion
class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {
        createRecordingsDirectoryIfNeeded()
    }
    
    /// Returns the URL for the recordings directory
    var recordingsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Recordings", isDirectory: true)
    }
    
    /// Creates the recordings directory if it doesn't exist
    private func createRecordingsDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Generates a new audio file URL with timestamp
    func generateAudioFileURL() -> URL {
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "recording_\(timestamp).m4a"
        return recordingsDirectory.appendingPathComponent(fileName)
    }
    
    /// Returns the full URL for a given audio file name
    func audioFileURL(for fileName: String) -> URL {
        return recordingsDirectory.appendingPathComponent(fileName)
    }
    
    /// Deletes an audio file
    func deleteAudioFile(fileName: String) throws {
        let fileURL = audioFileURL(for: fileName)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// Checks if an audio file exists
    func fileExists(fileName: String) -> Bool {
        let fileURL = audioFileURL(for: fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Calculates total storage used by all recordings
    func calculateTotalStorageUsed() -> Int64 {
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }
        
        return fileURLs.reduce(0) { total, url in
            guard let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
                return total
            }
            return total + Int64(fileSize)
        }
    }
    
    /// Formats bytes to readable string
    func formatStorageSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

