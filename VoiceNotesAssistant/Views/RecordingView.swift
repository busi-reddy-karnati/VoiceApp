//
//  RecordingView.swift
//  VoiceNotesApp
//
//  Main recording screen with record button and controls
//

import SwiftUI

/// Main screen for recording voice notes
struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Location badge (if available)
                if let location = viewModel.locationData,
                   let placeName = location.placeName {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text(placeName)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    Spacer()
                        .frame(height: 36)
                }
                
                Spacer()
                
                // Timer display
                Text(viewModel.formattedDuration(viewModel.recordingDuration))
                    .font(.system(size: 60, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(viewModel.isRecording ? .red : .primary)
                
                // Waveform visualization
                if viewModel.isRecording {
                    AudioWaveformView(audioLevel: viewModel.audioLevel)
                        .padding(.vertical, 20)
                } else {
                    Spacer()
                        .frame(height: 100)
                }
                
                // Warning message
                if viewModel.showingMaxDurationWarning {
                    Text("Approaching 2-minute limit")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Record button
                RecordButton(isRecording: viewModel.isRecording) {
                    Task {
                        if viewModel.isRecording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                }
                
                // Control buttons (pause/cancel)
                if viewModel.isRecording {
                    HStack(spacing: 40) {
                        // Pause/Resume button
                        Button(action: {
                            if viewModel.isPaused {
                                viewModel.resumeRecording()
                            } else {
                                viewModel.pauseRecording()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 32))
                                Text(viewModel.isPaused ? "Resume" : "Pause")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        // Cancel button
                        Button(action: {
                            Task {
                                await viewModel.cancelRecording()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                Text("Cancel")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 20)
                } else {
                    Spacer()
                        .frame(height: 80)
                }
                
                Spacer()
            }
            .padding()
        }
        .alert("Recording Saved", isPresented: $viewModel.showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your voice note has been saved and is being transcribed.")
        }
        .alert("Permission Required", isPresented: $viewModel.showingPermissionAlert) {
            Button("OK", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(viewModel.permissionAlertMessage)
        }
    }
}

#Preview {
    RecordingView()
}

