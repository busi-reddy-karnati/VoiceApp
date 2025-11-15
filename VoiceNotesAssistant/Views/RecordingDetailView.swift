//
//  RecordingDetailView.swift
//  VoiceNotesApp
//
//  Detailed view of a single recording with full transcript and metadata
//

import SwiftUI

/// Modal view showing full details of a recording
struct RecordingDetailView: View {
    let note: VoiceNote
    let playbackService: AudioPlaybackService
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Audio player section
                    VStack(spacing: 16) {
                        // Play/Pause button
                        Button(action: {
                            if let fileName = note.audioFileName {
                                do {
                                    try playbackService.togglePlayPause(fileName: fileName)
                                } catch {
                                    print("Playback error: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Progress bar
                        if isPlaying || playbackService.currentlyPlayingFileName == note.audioFileName {
                            VStack(spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 4)
                                            .cornerRadius(2)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(
                                                width: geometry.size.width * CGFloat(playbackService.playbackProgress),
                                                height: 4
                                            )
                                            .cornerRadius(2)
                                    }
                                }
                                .frame(height: 4)
                                
                                HStack {
                                    Text(formatTime(playbackService.currentTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatTime(playbackService.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .monospacedDigit()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Metadata section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        MetadataRow(
                            icon: "calendar",
                            label: "Date",
                            value: formatDate(note.createdAt)
                        )
                        
                        MetadataRow(
                            icon: "clock",
                            label: "Time",
                            value: formatTime(note.createdAt)
                        )
                        
                        MetadataRow(
                            icon: "timer",
                            label: "Duration",
                            value: formatDuration(note.duration)
                        )
                        
                        if let placeName = note.placeName, !placeName.isEmpty {
                            MetadataRow(
                                icon: "location.fill",
                                label: "Location",
                                value: placeName
                            )
                        }
                        
                        if let address = note.address, !address.isEmpty {
                            MetadataRow(
                                icon: "mappin.circle",
                                label: "Address",
                                value: address
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Transcript section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcript")
                            .font(.headline)
                        
                        if note.isTranscribing {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Transcribing your recording...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 20)
                        } else if let transcript = note.transcript, !transcript.isEmpty {
                            Text(transcript)
                                .font(.body)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                        } else {
                            Text("No transcript available")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Delete button
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Recording")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Recording", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this recording? This action cannot be undone.")
            }
        }
    }
    
    private var isPlaying: Bool {
        playbackService.currentlyPlayingFileName == note.audioFileName && playbackService.isPlaying
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Helper view for metadata rows
struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .font(.subheadline)
    }
}

