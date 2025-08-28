//
//  ImportOptionsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct ImportOptionsView: View {
    @Binding var showingFilePicker: Bool
    @Binding var showingJellyfinSetup: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingFilePicker = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from Files")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Choose audiobook files from the Files app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        // AirDrop is handled automatically by the system
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "wifi.circle")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AirDrop")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Receive files via AirDrop from Mac or iOS device")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        showingJellyfinSetup = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jellyfin Server")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Download from your personal Jellyfin server")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        // TODO: Implement URL download
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Download from URL")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Enter a direct URL to an audiobook file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supported Formats")
                            .font(.headline)
                        
                        HStack {
                            ForEach(["M4B", "M4A", "MP3", "FLAC"], id: \.self) { format in
                                Text(format)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                        }
                        
                        Text("ZIP archives containing audiobook folders are also supported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iTunes File Sharing")
                            .font(.headline)
                        
                        Text("You can also add files through iTunes File Sharing on your Mac or PC:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Connect your device to iTunes")
                            Text("2. Select your device")
                            Text("3. Go to File Sharing")
                            Text("4. Select BookJack")
                            Text("5. Drag audiobook files to the app")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Import Audiobooks")
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

struct JellyfinSetupView: View {
    @AppStorage("jellyfinServerURL") private var serverURL = ""
    @AppStorage("jellyfinUsername") private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    @State private var connectionStatus = ""
    @State private var showingBrowser = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server Details") {
                    TextField("Server URL", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button(action: connectToServer) {
                        HStack {
                            if isConnecting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isConnecting ? "Connecting..." : "Connect")
                        }
                    }
                    .disabled(serverURL.isEmpty || username.isEmpty || password.isEmpty || isConnecting)
                    
                    if !connectionStatus.isEmpty {
                        Text(connectionStatus)
                            .font(.caption)
                            .foregroundColor(connectionStatus.contains("Success") ? .green : .red)
                    }
                }
                
                if !serverURL.isEmpty && !connectionStatus.contains("Failed") {
                    Section("Browse Library") {
                        Button("Browse Audiobooks") {
                            showingBrowser = true
                        }
                        .disabled(connectionStatus.isEmpty)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is Jellyfin?")
                            .font(.headline)
                        
                        Text("Jellyfin is a free, open-source media server that you can run on your own hardware. It allows you to organize and stream your personal audiobook collection.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Link("Learn more about Jellyfin", destination: URL(string: "https://jellyfin.org")!)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Jellyfin Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingBrowser) {
                JellyfinBrowserView(serverURL: serverURL, username: username, password: password)
            }
        }
    }
    
    private func connectToServer() {
        isConnecting = true
        connectionStatus = ""
        
        // Simulate connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isConnecting = false
            
            // Simple validation
            if serverURL.starts(with: "http") {
                connectionStatus = "✓ Connection successful"
            } else {
                connectionStatus = "✗ Connection failed. Please check your server URL."
            }
        }
    }
}

struct JellyfinBrowserView: View {
    let serverURL: String
    let username: String
    let password: String
    
    @State private var audiobooks: [JellyfinAudiobook] = []
    @State private var isLoading = true
    @State private var selectedBooks: Set<String> = []
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading audiobooks...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if audiobooks.isEmpty {
                    VStack {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Audiobooks Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Make sure your Jellyfin server has audiobooks in the library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(audiobooks) { audiobook in
                            HStack {
                                AsyncImage(url: audiobook.imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray5))
                                        .overlay {
                                            Image(systemName: "book.closed")
                                                .foregroundColor(.secondary)
                                        }
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(audiobook.title)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    Text(audiobook.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text(formatFileSize(audiobook.size))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedBooks.contains(audiobook.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedBooks.contains(audiobook.id) {
                                    selectedBooks.remove(audiobook.id)
                                } else {
                                    selectedBooks.insert(audiobook.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Jellyfin Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Download") {
                        downloadSelectedBooks()
                    }
                    .disabled(selectedBooks.isEmpty)
                }
            }
            .onAppear {
                loadAudiobooks()
            }
        }
    }
    
    private func loadAudiobooks() {
        // Simulate loading audiobooks from Jellyfin
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            audiobooks = [
                JellyfinAudiobook(
                    id: "1",
                    title: "The Great Gatsby",
                    author: "F. Scott Fitzgerald",
                    size: 125000000,
                    imageURL: nil,
                    downloadURL: URL(string: "\(serverURL)/audiobook1.m4b")!
                ),
                JellyfinAudiobook(
                    id: "2",
                    title: "1984",
                    author: "George Orwell",
                    size: 180000000,
                    imageURL: nil,
                    downloadURL: URL(string: "\(serverURL)/audiobook2.m4b")!
                )
            ]
            isLoading = false
        }
    }
    
    private func downloadSelectedBooks() {
        // TODO: Implement actual download from Jellyfin
        print("Downloading \(selectedBooks.count) audiobooks")
        dismiss()
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct JellyfinAudiobook: Identifiable {
    let id: String
    let title: String
    let author: String
    let size: Int64
    let imageURL: URL?
    let downloadURL: URL
}

#Preview {
    ImportOptionsView(showingFilePicker: .constant(false), showingJellyfinSetup: .constant(false))
}
