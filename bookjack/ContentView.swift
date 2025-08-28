//
//  ContentView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    
    var body: some View {
        TabView {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            
            PlaylistsView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .overlay(alignment: .bottom) {
            if audioPlayer.currentAudiobook != nil {
                MiniPlayerView()
                    .padding(.bottom, 49) // Account for tab bar height
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Audiobook.self, inMemory: true)
}
