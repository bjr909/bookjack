//
//  SettingsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @AppStorage("smartRewindEnabled") private var smartRewindEnabled = true
    
    @State private var showingAbout = false
    @State private var showingClearProgress = false
    
    var body: some View {
        NavigationStack {
            List {
                // Playback Settings
                Section("Playback") {
                    HStack {
                        Text("Default Speed")
                        Spacer()
                        Text("\(defaultPlaybackSpeed, specifier: "%.1f")×")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $defaultPlaybackSpeed, in: 0.5...3.0, step: 0.1)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Smart Rewind", isOn: $smartRewindEnabled)
                        Text("Automatically rewinds a few seconds when resuming playback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Library Settings
                Section("Library") {
                    NavigationLink("File Management") {
                        FileManagementView()
                    }
                    
                    Button("Clear All Progress") {
                        showingClearProgress = true
                    }
                    .foregroundColor(.red)
                }
                
                // Interface Settings
                Section("Interface") {
                    NavigationLink("Appearance") {
                        AppearanceSettingsView()
                    }
                }
                
                // Support & Info
                Section("Support") {
                    NavigationLink("Help & FAQ") {
                        HelpView()
                    }
                    
                    Button("About") {
                        showingAbout = true
                    }
                    
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .alert("Clear All Progress", isPresented: $showingClearProgress) {
                Button("Clear All", role: .destructive) {
                    clearAllProgress()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset the listening progress for all audiobooks. This action cannot be undone.")
            }
        }
    }
    
    private func clearAllProgress() {
        // TODO: Implement clearing all progress
        print("Clearing all progress...")
    }
}



struct FileManagementView: View {
    @State private var storageUsed: String = "Calculating..."
    @State private var showingClearCache = false
    
    var body: some View {
        List {
            Section("Storage") {
                HStack {
                    Text("Used Space")
                    Spacer()
                    Text(storageUsed)
                        .foregroundColor(.secondary)
                }
                
                Button("Clear Cache") {
                    showingClearCache = true
                }
                
                Button("Optimize Storage") {
                    // TODO: Implement storage optimization
                }
            }
            
            Section("File Organization") {
                NavigationLink("Organize by Author") {
                    // TODO: Implement file organization
                    Text("File Organization Options")
                }
                
                NavigationLink("Duplicate Detection") {
                    // TODO: Implement duplicate detection
                    Text("Duplicate Detection")
                }
            }
        }
        .navigationTitle("File Management")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateStorageUsed()
        }
        .alert("Clear Cache", isPresented: $showingClearCache) {
            Button("Clear", role: .destructive) {
                clearCache()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear temporary files and thumbnails. Your audiobooks will not be affected.")
        }
    }
    
    private func calculateStorageUsed() {
        // TODO: Implement actual storage calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            storageUsed = "1.2 GB"
        }
    }
    
    private func clearCache() {
        // TODO: Implement cache clearing
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme = "System"
    @AppStorage("accentColor") private var accentColor = "Blue"
    @AppStorage("showArtwork") private var showArtwork = true
    @AppStorage("gridSize") private var gridSize = "Medium"
    
    let colorSchemes = ["System", "Light", "Dark"]
    let accentColors = ["Blue", "Purple", "Green", "Orange", "Red"]
    let gridSizes = ["Small", "Medium", "Large"]
    
    var body: some View {
        List {
            Section("Theme") {
                Picker("Appearance", selection: $colorScheme) {
                    ForEach(colorSchemes, id: \.self) { scheme in
                        Text(scheme).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                
                Picker("Accent Color", selection: $accentColor) {
                    ForEach(accentColors, id: \.self) { color in
                        Text(color).tag(color)
                    }
                }
            }
            
            Section("Library Display") {
                Toggle("Show Artwork", isOn: $showArtwork)
                
                Picker("Grid Size", selection: $gridSize) {
                    ForEach(gridSizes, id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}



struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("Importing Audiobooks") {
                    HelpDetailView(
                        title: "Importing Audiobooks",
                        content: """
                        To import audiobooks to BookJack:
                        
                        1. Tap the + button in the Library
                        2. Select "Import Options"
                        3. Choose "Import from Files"
                        4. Select your audiobook files
                        
                        Supported formats: M4B, M4A, MP3, FLAC
                        ZIP archives containing audiobook folders are also supported.
                        """
                    )
                }
                
                NavigationLink("Player Controls") {
                    HelpDetailView(
                        title: "Player Controls",
                        content: """
                        Basic Controls:
                        • Tap artwork to play/pause
                        • Use the progress slider to skip to different parts
                        • Tap chapter title to view all chapters
                        • Swipe down on full player to return to library
                        
                        Speed Control:
                        • Tap the speed button to adjust playback speed
                        • Range from 0.5× to 3.0× speed
                        
                        Sleep Timer:
                        • Set a timer to automatically pause playback
                        • Perfect for listening before bed
                        """
                    )
                }
            }
            
            Section("Troubleshooting") {
                NavigationLink("Common Issues") {
                    HelpDetailView(
                        title: "Common Issues",
                        content: """
                        Playback Problems:
                        • Ensure your audiobook files are not corrupted
                        • Try restarting the app if playback stops unexpectedly
                        • Check that your device has sufficient storage space
                        
                        Import Issues:
                        • Make sure files are in supported formats (M4B, M4A, MP3, FLAC)
                        • Large files may take longer to import
                        • Ensure files are not DRM-protected
                        
                        Performance:
                        • Clear cache in File Management if the app feels slow
                        • Restart the app periodically for optimal performance
                        """
                    )
                }
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(content)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("BookJack")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("A powerful audiobook player for iOS")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Created by Brett Ridenour")
                        .font(.headline)
                    
                    Text("Built with SwiftUI and AVFoundation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by parent
                    }
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                    
                    Text("BookJack does not collect, store, or transmit any personal data. All audiobook files and listening progress are stored locally on your device.")
                    
                    Text("File Storage")
                        .font(.headline)
                    
                    Text("Your audiobook files are stored securely in the app's private storage area on your device. Only BookJack can access these files.")
                    
                    Text("Analytics")
                        .font(.headline)
                    
                    Text("BookJack does not use any analytics or tracking services. Your listening habits and preferences remain completely private.")
                    
                    Text("Contact")
                        .font(.headline)
                    
                    Text("If you have any questions about this privacy policy, please contact us through the App Store.")
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
