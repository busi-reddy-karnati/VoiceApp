//
//  RecordingsListView.swift
//  VoiceNotesApp
//
//  List view showing all recorded voice notes grouped by date
//

import SwiftUI

/// Screen displaying all voice notes in a grouped list
struct RecordingsListView: View {
    @StateObject private var viewModel = RecordingsListViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.voiceNotes.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "mic.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Recordings Yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Tap the Record tab to create your first voice note")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Recordings list
                    ScrollView {
                        LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.groupedNotes.keys.sorted(), id: \.self) { dateGroup in
                                Section {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.groupedNotes[dateGroup] ?? [], id: \.id) { note in
                                            RecordingCard(
                                                note: note,
                                                isPlaying: viewModel.isPlaying(note),
                                                onPlayPause: {
                                                    viewModel.togglePlayback(for: note)
                                                },
                                                onTap: {
                                                    viewModel.showDetail(for: note)
                                                }
                                            )
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    viewModel.deleteNote(note)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                } header: {
                                    HStack {
                                        Text(dateGroup.displayName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Voice Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Text("Storage Used: \(viewModel.totalStorageUsed)")
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingDetailView) {
                if let note = viewModel.selectedNote {
                    RecordingDetailView(
                        note: note,
                        playbackService: viewModel.getPlaybackService(),
                        onDelete: {
                            viewModel.deleteNote(note)
                            viewModel.showingDetailView = false
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.fetchNotes()
            viewModel.calculateStorage()
        }
    }
}

#Preview {
    RecordingsListView()
}

