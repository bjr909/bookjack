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
    @AppStorage("volumeBoostEnabled") private var volumeBoostEnabled = false
    @AppStorage("autoBookmarkEnabled") private var autoBookmarkEnabled = true
    @AppStorage("skipSilenceEnabled") private var skipSilenceEnabled = false


    @AppStorage("hardcoverEnabled") private var hardcoverEnabled = false
    

    @State private var showingAbout = false
    
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
                    
                    Toggle("Smart Rewind", isOn: $smartRewindEnabled)
                    
                    Toggle("Volume Boost", isOn: $volumeBoostEnabled)
                    
                    Toggle("Auto Bookmark", isOn: $autoBookmarkEnabled)
                    
                    Toggle("Skip Silence", isOn: $skipSilenceEnabled)
                }
                
                // Library Settings
                Section("Library") {
                    NavigationLink("Import Settings") {
                        ImportSettingsView()
                    }
                    
                    NavigationLink("File Management") {
                        FileManagementView()
                    }
                    
                    Button("Clear All Progress") {
                        // TODO: Implement with confirmation
                    }
                    .foregroundColor(.red)
                }
                
                // Sync Settings
                Section("Sync & Backup") {
                    Toggle("iCloud Sync", isOn: .constant(true))
                        .disabled(true) // TODO: Implement iCloud sync
                    
                    Toggle("Hardcover.app Integration", isOn: $hardcoverEnabled)
                }
                
                // Interface Settings
                Section("Interface") {
                    NavigationLink("Appearance") {
                        AppearanceSettingsView()
                    }
                    
                    NavigationLink("Accessibility") {
                        AccessibilitySettingsView()
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
        }
    }
}

struct ImportSettingsView: View {
    @AppStorage("autoImportEnabled") private var autoImportEnabled = true
    @AppStorage("extractMetadataEnabled") private var extractMetadataEnabled = true
    @AppStorage("generateChaptersEnabled") private var generateChaptersEnabled = true
    @AppStorage("importQuality") private var importQuality = "High"
    
    let qualityOptions = ["Low", "Medium", "High", "Lossless"]
    
    var body: some View {
        List {
            Section("Import Behavior") {
                Toggle("Auto-import from Files", isOn: $autoImportEnabled)
                
                Toggle("Extract Metadata", isOn: $extractMetadataEnabled)
                
                Toggle("Generate Chapters", isOn: $generateChaptersEnabled)
            }
            
            Section("Quality") {
                Picker("Import Quality", selection: $importQuality) {
                    ForEach(qualityOptions, id: \.self) { quality in
                        Text(quality).tag(quality)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
            
            Section("File Types") {
                HStack {
                    Text("Supported Formats")
                    Spacer()
                    Text("M4B, M4A, MP3, FLAC")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Import Settings")
        .navigationBarTitleDisplayMode(.inline)
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

struct AccessibilitySettingsView: View {
    @AppStorage("largeText") private var largeText = false
    @AppStorage("highContrast") private var highContrast = false
    @AppStorage("voiceOverEnabled") private var voiceOverEnabled = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    
    var body: some View {
        List {
            Section("Text & Display") {
                Toggle("Large Text", isOn: $largeText)
                
                Toggle("High Contrast", isOn: $highContrast)
            }
            
            Section("Interaction") {
                Toggle("VoiceOver Support", isOn: $voiceOverEnabled)
                
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
            }
            
            Section("Controls") {
                Text("Gesture Controls")
                Text("• Tap artwork to play/pause")
                Text("• Swipe left/right to skip")
                Text("• Long press for context menu")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("Importing Audiobooks") {
                    Text("How to import audiobooks...")
                }
                

                
                NavigationLink("Player Controls") {
                    Text("Understanding the player interface...")
                }
            }
            
            Section("Troubleshooting") {
                NavigationLink("Playback Issues") {
                    Text("Common playback problems and solutions...")
                }
                
                NavigationLink("Import Problems") {
                    Text("File import troubleshooting...")
                }
                
                NavigationLink("Sync Issues") {
                    Text("Cloud sync troubleshooting...")
                }
            }
            
            Section("Contact") {
                Button("Send Feedback") {
                    // TODO: Implement feedback
                }
                
                Button("Report Bug") {
                    // TODO: Implement bug reporting
                }
            }
        }
        .navigationTitle("Help & FAQ")
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
                    
                    Text("BookJack does not collect any personal data. All audiobook files and listening progress are stored locally on your device.")
                    
                    Text("iCloud Sync")
                        .font(.headline)
                    
                    Text("When enabled, your library and progress data are synced through your personal iCloud account. This data is encrypted and only accessible to you.")
                    
                    Text("Third-Party Services")
                        .font(.headline)
                    
                    Text("BookJack may integrate with optional third-party services like Jellyfin servers. Data shared with these services is subject to their respective privacy policies.")
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
