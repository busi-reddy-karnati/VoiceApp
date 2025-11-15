//
//  AudioWaveformView.swift
//  VoiceNotesApp
//
//  Visual representation of audio levels during recording
//

import SwiftUI

/// Animated waveform visualization for audio levels
struct AudioWaveformView: View {
    let audioLevel: Float
    
    private let barCount = 5
    @State private var animatedLevels: [CGFloat] = Array(repeating: 0.2, count: 5)
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6)
                    .frame(height: calculateBarHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.1),
                        value: animatedLevels[index]
                    )
            }
        }
        .frame(height: 60)
        .onChange(of: audioLevel) { oldValue, newValue in
            updateWaveform(level: CGFloat(newValue))
        }
    }
    
    private func calculateBarHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 60
        
        // Create a wave pattern
        let waveOffset = abs(CGFloat(index) - CGFloat(barCount) / 2.0)
        let heightMultiplier = 1.0 - (waveOffset * 0.2)
        
        let targetHeight = baseHeight + (maxHeight - baseHeight) * animatedLevels[index] * heightMultiplier
        return max(baseHeight, targetHeight)
    }
    
    private func updateWaveform(level: CGFloat) {
        // Shift existing levels
        for i in (1..<barCount).reversed() {
            animatedLevels[i] = animatedLevels[i - 1]
        }
        
        // Add new level with some randomness for visual effect
        let randomFactor = CGFloat.random(in: 0.8...1.2)
        animatedLevels[0] = min(1.0, level * randomFactor)
    }
}

#Preview {
    VStack(spacing: 40) {
        AudioWaveformView(audioLevel: 0.3)
        AudioWaveformView(audioLevel: 0.7)
        AudioWaveformView(audioLevel: 1.0)
    }
    .padding()
}

