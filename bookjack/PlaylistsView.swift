//
//  PlaylistsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI
import SwiftData

struct PlaylistsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var playlists: [Playlist]
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        NavigationStack {
            if playlists.isEmpty {
                EmptyPlaylistsView(showingCreatePlaylist: $showingCreatePlaylist)
            } else {
                List {
                    ForEach(playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistRowView(playlist: playlist)
                        }
                    }
                    .onDelete(perform: deletePlaylists)
                }
            }
        }
        .navigationTitle("Playlists")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreatePlaylist = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Playlist", isPresented: $showingCreatePlaylist) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Create") {
                createPlaylist()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a name for your new playlist")
        }
    }
    
    private func createPlaylist() {
        guard !newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let playlist = Playlist(name: newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(playlist)
        
        do {
            try modelContext.save()
            newPlaylistName = ""
        } catch {
            print("Failed to create playlist: \(error)")
        }
    }
    
    private func deletePlaylists(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(playlists[index])
            }
        }
    }
}

struct EmptyPlaylistsView: View {
    @Binding var showingCreatePlaylist: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Playlists")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create playlists to organize your audiobooks")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingCreatePlaylist = true }) {
                Label("Create Playlist", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct PlaylistRowView: View {
    let playlist: Playlist
    
    var body: some View {
        HStack {
            // Playlist artwork (composite of first few audiobooks)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                
                if let firstAudiobook = playlist.audiobooks.first,
                   let artwork = firstAudiobook.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                
                Text("\(playlist.audiobooks.count) audiobook\(playlist.audiobooks.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let nextBook = playlist.nextUnfinishedAudiobook {
                    Text("Next: \(nextBook.title)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if playlist.isAutoPlay {
                Image(systemName: "repeat")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @Environment(\.modelContext) private var modelContext
    @Query private var audiobooks: [Audiobook]
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    
    @State private var showingAddAudiobooks = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(playlist.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(playlist.audiobooks.count) audiobook\(playlist.audiobooks.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let totalDuration = calculateTotalDuration() {
                            Text("Total: \(formatDuration(totalDuration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let nextBook = playlist.nextUnfinishedAudiobook {
                        Button(action: {
                            audioPlayer.loadAudiobook(nextBook)
                        }) {
                            VStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("Play Next")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Settings") {
                Toggle("Auto-play next audiobook", isOn: Binding(
                    get: { playlist.isAutoPlay },
                    set: { playlist.isAutoPlay = $0 }
                ))
            }
            
            Section("Audiobooks") {
                if playlist.audiobooks.isEmpty {
                    Text("No audiobooks in this playlist")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(playlist.audiobooks) { audiobook in
                        AudiobookRowView(audiobook: audiobook)
                            .onTapGesture {
                                audioPlayer.loadAudiobook(audiobook)
                            }
                    }
                    .onDelete(perform: removeAudiobooks)
                    .onMove(perform: moveAudiobooks)
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingAddAudiobooks = true }) {
                        Image(systemName: "plus")
                    }
                    
                    EditButton()
                }
            }
        }
        .sheet(isPresented: $showingAddAudiobooks) {
            AddAudiobooksToPlaylistView(playlist: playlist, availableAudiobooks: audiobooks)
        }
    }
    
    private func calculateTotalDuration() -> TimeInterval? {
        let total = playlist.audiobooks.reduce(0) { $0 + $1.duration }
        return total > 0 ? total : nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func removeAudiobooks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                if let audiobook = playlist.audiobooks[safe: index] {
                    playlist.audiobooks.removeAll { $0.id == audiobook.id }
                }
            }
        }
    }
    
    private func moveAudiobooks(from source: IndexSet, to destination: Int) {
        playlist.audiobooks.move(fromOffsets: source, toOffset: destination)
    }
}

struct AudiobookRowView: View {
    let audiobook: Audiobook
    
    var body: some View {
        HStack {
            if let artwork = audiobook.artwork {
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(audiobook.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(audiobook.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if audiobook.progress > 0 && !audiobook.isFinished {
                    ProgressView(value: audiobook.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
            
            Spacer()
            
            if audiobook.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddAudiobooksToPlaylistView: View {
    let playlist: Playlist
    let availableAudiobooks: [Audiobook]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAudiobooks: Set<UUID> = []
    
    var filteredAudiobooks: [Audiobook] {
        availableAudiobooks.filter { audiobook in
            !playlist.audiobooks.contains { $0.id == audiobook.id }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAudiobooks) { audiobook in
                    HStack {
                        AudiobookRowView(audiobook: audiobook)
                        
                        Spacer()
                        
                        if selectedAudiobooks.contains(audiobook.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedAudiobooks.contains(audiobook.id) {
                            selectedAudiobooks.remove(audiobook.id)
                        } else {
                            selectedAudiobooks.insert(audiobook.id)
                        }
                    }
                }
            }
            .navigationTitle("Add Audiobooks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSelectedAudiobooks()
                    }
                    .disabled(selectedAudiobooks.isEmpty)
                }
            }
        }
    }
    
    private func addSelectedAudiobooks() {
        for audiobookId in selectedAudiobooks {
            if let audiobook = availableAudiobooks.first(where: { $0.id == audiobookId }) {
                playlist.audiobooks.append(audiobook)
            }
        }
        dismiss()
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    PlaylistsView()
        .modelContainer(for: Playlist.self, inMemory: true)
}
