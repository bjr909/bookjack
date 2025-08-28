//
//  FullPlayerView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct FullPlayerView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isSeekingSlider = false
    @State private var seekValue: Double = 0
    @State private var showingChapters = false
    @State private var showingSleepTimer = false
    @State private var showingSpeedControl = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Artwork
                VStack {
                    if let artwork = audioPlayer.currentAudiobook?.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray5))
                            .frame(width: 300, height: 300)
                            .overlay {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 80))
                                    .foregroundColor(.secondary)
                            }
                            .shadow(radius: 10)
                    }
                }
                
                Spacer()
                
                // Title and Author
                VStack(spacing: 8) {
                    Text(audioPlayer.currentAudiobook?.title ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(audioPlayer.currentAudiobook?.author ?? "")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let chapter = audioPlayer.currentChapter {
                        Text(chapter.title)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                // Progress Slider
                VStack(spacing: 8) {
                    if let chapter = audioPlayer.currentChapter {
                        // Chapter progress
                        Slider(
                            value: isSeekingSlider ? $seekValue : Binding(
                                get: { audioPlayer.currentTime - chapter.startTime },
                                set: { _ in }
                            ),
                            in: 0...max(chapter.duration, 1),
                            onEditingChanged: { editing in
                                isSeekingSlider = editing
                                if !editing {
                                    audioPlayer.seek(to: chapter.startTime + seekValue)
                                }
                            }
                        )
                        .accentColor(.primary)
                        
                        HStack {
                            Text(formatTime(audioPlayer.currentTime - chapter.startTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("-\(formatTime(chapter.endTime - audioPlayer.currentTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Book progress (fallback when no chapters)
                        Slider(
                            value: isSeekingSlider ? $seekValue : Binding(
                                get: { audioPlayer.currentTime },
                                set: { _ in }
                            ),
                            in: 0...max(audioPlayer.duration, 1),
                            onEditingChanged: { editing in
                                isSeekingSlider = editing
                                if !editing {
                                    audioPlayer.seek(to: seekValue)
                                }
                            }
                        )
                        .accentColor(.primary)
                        
                        HStack {
                            Text(formatTime(audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("-\(formatTime(audioPlayer.duration - audioPlayer.currentTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Main Controls
                HStack(spacing: 40) {
                    Button(action: { audioPlayer.skipBackward() }) {
                        Image(systemName: "gobackward.30")
                            .font(.system(size: 32))
                    }
                    
                    Button(action: {
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else {
                            audioPlayer.play()
                        }
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                    }
                    
                    Button(action: { audioPlayer.skipForward() }) {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 32))
                    }
                }
                .foregroundColor(.primary)
                
                // Secondary Controls
                HStack {
                    // Speed Control
                    Button(action: { showingSpeedControl = true }) {
                        Text("\(audioPlayer.playbackRate, specifier: "%.1f")×")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    // Chapters
                    if !(audioPlayer.currentAudiobook?.chapters.isEmpty ?? true) {
                        Button(action: { showingChapters = true }) {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                        }
                    }
                    
                    // Sleep Timer
                    Button(action: { showingSleepTimer = true }) {
                        Image(systemName: audioPlayer.sleepTimerRemaining > 0 ? "moon.fill" : "moon")
                            .font(.title2)
                            .foregroundColor(audioPlayer.sleepTimerRemaining > 0 ? .accentColor : .primary)
                    }
                    

                }
                .padding(.horizontal)
                
                // Sleep Timer Display
                if audioPlayer.sleepTimerRemaining > 0 {
                    Text("Sleep Timer: \(formatTime(audioPlayer.sleepTimerRemaining))")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        if gesture.translation.height > 100 && gesture.velocity.height > 500 {
                            dismiss()
                        }
                    }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingChapters) {
                ChaptersView()
            }
            .sheet(isPresented: $showingSleepTimer) {
                SleepTimerView()
            }
            .sheet(isPresented: $showingSpeedControl) {
                SpeedControlView()
            }
        }
        .onAppear {
            if let chapter = audioPlayer.currentChapter {
                seekValue = audioPlayer.currentTime - chapter.startTime
            } else {
                seekValue = audioPlayer.currentTime
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct ChaptersView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(audioPlayer.currentAudiobook?.chapters.sorted(by: { $0.startTime < $1.startTime }) ?? []) { chapter in
                    Button(action: {
                        audioPlayer.jumpToChapter(chapter)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chapter.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Start: \(formatTime(chapter.startTime)) - Duration: \(formatTime(chapter.duration))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if audioPlayer.currentChapter?.id == chapter.id {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

struct SleepTimerView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let timerOptions: [TimeInterval] = [
        5 * 60,   // 5 minutes
        10 * 60,  // 10 minutes
        15 * 60,  // 15 minutes
        30 * 60,  // 30 minutes
        45 * 60,  // 45 minutes
        60 * 60,  // 1 hour
        90 * 60,  // 1.5 hours
        120 * 60  // 2 hours
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if audioPlayer.sleepTimerRemaining > 0 {
                        HStack {
                            Text("Timer Active")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formatTime(audioPlayer.sleepTimerRemaining))
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Cancel Timer") {
                            audioPlayer.cancelSleepTimer()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    } else {
                        Text("Pause playback after:")
                            .font(.headline)
                    }
                }
                
                Section {
                    ForEach(timerOptions, id: \.self) { duration in
                        Button(action: {
                            audioPlayer.startSleepTimer(duration: duration)
                            dismiss()
                        }) {
                            HStack {
                                Text(formatDuration(duration))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if audioPlayer.sleepTimerRemaining > 0 && 
                                   abs(audioPlayer.sleepTimerRemaining - duration) < 60 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    
                    Button("End of Current Chapter") {
                        if let chapter = audioPlayer.currentChapter {
                            let remainingInChapter = chapter.endTime - audioPlayer.currentTime
                            audioPlayer.startSleepTimer(duration: remainingInChapter)
                            dismiss()
                        }
                    }
                    .disabled(audioPlayer.currentChapter == nil)
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")\(minutes > 0 ? " \(minutes) min" : "")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

struct SpeedControlView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Playback Speed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(audioPlayer.playbackRate, specifier: "%.2f")×")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                
                Slider(
                    value: Binding(
                        get: { audioPlayer.playbackRate },
                        set: { audioPlayer.setPlaybackRate($0) }
                    ),
                    in: 0.5...3.0,
                    step: 0.25
                )
                .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(speedOptions, id: \.self) { speed in
                        Button(action: {
                            audioPlayer.setPlaybackRate(speed)
                        }) {
                            Text("\(speed, specifier: "%.2f")×")
                                .font(.headline)
                                .foregroundColor(audioPlayer.playbackRate == speed ? .white : .primary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(audioPlayer.playbackRate == speed ? Color.accentColor : Color(.systemGray6))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FullPlayerView()
}
