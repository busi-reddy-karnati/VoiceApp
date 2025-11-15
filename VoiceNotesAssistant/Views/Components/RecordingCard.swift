//
//  RecordingCard.swift
//  VoiceNotesApp
//
//  Card view for displaying a recording in the list
//

import SwiftUI

/// Card displaying recording information
struct RecordingCard: View {
    let note: VoiceNote
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: onPlayPause) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Recording info
                VStack(alignment: .leading, spacing: 4) {
                    // Time and duration
                    HStack {
                        Text(formattedTime)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formattedDuration)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Location
                    if let placeName = note.placeName, !placeName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(placeName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Transcript or transcribing status
                    if note.isTranscribing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Transcribing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let transcript = note.transcript, !transcript.isEmpty {
                        Text(transcript)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedTime: String {
        guard let createdAt = note.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    private var formattedDuration: String {
        let minutes = Int(note.duration) / 60
        let seconds = Int(note.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

