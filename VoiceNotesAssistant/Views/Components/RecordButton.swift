//
//  RecordButton.swift
//  VoiceNotesApp
//
//  Large circular record button with animations
//

import SwiftUI

/// Prominent record button with state-based appearance
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 120, height: 120)
                
                // Pulsing animation when recording
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                }
                
                // Icon
                Image(systemName: isRecording ? "stop.fill" : "circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .scaleEffect(isRecording ? 0.6 : 1.0)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onChange(of: isRecording) { oldValue, newValue in
            if newValue {
                startPulsing()
            } else {
                stopPulsing()
            }
        }
        .onAppear {
            if isRecording {
                startPulsing()
            }
        }
    }
    
    private func startPulsing() {
        isPulsing = false
        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
    }
    
    private func stopPulsing() {
        withAnimation(.easeOut(duration: 0.3)) {
            isPulsing = false
        }
    }
}

/// Custom button style with scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(isRecording: false) {
            print("Start recording")
        }
        
        RecordButton(isRecording: true) {
            print("Stop recording")
        }
    }
}

