//
//  MiniPlayerView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct MiniPlayerView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    @State private var showingFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(x: 1, y: 0.5)
            
            HStack(spacing: 12) {
                // Artwork
                if let artwork = audioPlayer.currentAudiobook?.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "book.closed")
                                .foregroundColor(.secondary)
                        }
                }
                
                // Title and Author
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioPlayer.currentAudiobook?.title ?? "")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(audioPlayer.currentAudiobook?.author ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: { audioPlayer.skipBackward() }) {
                        Image(systemName: "gobackward.30")
                            .font(.title2)
                    }
                    
                    Button(action: { 
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else {
                            audioPlayer.play()
                        }
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                    }
                    
                    Button(action: { audioPlayer.skipForward() }) {
                        Image(systemName: "goforward.30")
                            .font(.title2)
                    }
                }
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
        .onTapGesture {
            showingFullPlayer = true
        }
        .fullScreenCover(isPresented: $showingFullPlayer) {
            FullPlayerView()
        }
    }
}

#Preview {
    MiniPlayerView()
}
