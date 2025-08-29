//
//  SettingsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var audiobooks: [Audiobook]
    
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @AppStorage("smartRewindEnabled") private var smartRewindEnabled = true
    @AppStorage("smartRewindSeconds") private var smartRewindSeconds: Double = 30
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("accentColor") private var accentColor: String = "blue"
    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Smart Rewind", isOn: $smartRewindEnabled)
                        
                        if smartRewindEnabled {
                            Text("When resuming playback, automatically rewind \(Int(smartRewindSeconds)) seconds to help you remember where you left off.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 32)
                            
                            HStack {
                                Text("Rewind Duration")
                                Spacer()
                                Text("\(Int(smartRewindSeconds))s")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 32)
                            
                            Slider(value: $smartRewindSeconds, in: 5...60, step: 5)
                                .listRowInsets(EdgeInsets(top: 0, leading: 52, bottom: 0, trailing: 20))
                        }
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
                    
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
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
        // Reset progress for all audiobooks
        for audiobook in audiobooks {
            audiobook.currentPosition = 0
            audiobook.isFinished = false
            audiobook.dateLastPlayed = nil
        }
        
        // Save changes to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Failed to clear progress: \(error)")
        }
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

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("Acceptance of Terms")
                        .font(.headline)
                    
                    Text("By downloading and using BookJack, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.")
                    
                    Text("App Usage")
                        .font(.headline)
                    
                    Text("BookJack is designed for personal use to play audiobook files that you own or have the right to use. You are responsible for ensuring you have the legal right to play any content through this app.")
                    
                    Text("Content Responsibility")
                        .font(.headline)
                    
                    Text("You are solely responsible for the audiobook content you import and play through BookJack. The app does not provide, host, or distribute any copyrighted content.")
                    
                    Text("Prohibited Uses")
                        .font(.headline)
                    
                    Text("You may not use BookJack to play content that infringes on copyright or other intellectual property rights. You may not use the app for any illegal purposes.")
                    
                    Text("Disclaimer")
                        .font(.headline)
                    
                    Text("BookJack is provided 'as is' without warranties of any kind. The developer is not responsible for any issues arising from the use of the app or your audiobook content.")
                    
                    Text("Contact")
                        .font(.headline)
                    
                    Text("If you have any questions about these terms, please contact us through the App Store.")
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
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
                    optimizeStorage()
                }
            }
            
            Section("File Organization") {
                Button("Organize by Author") {
                    organizeByAuthor()
                }
                
                Button("Find Duplicates") {
                    findDuplicates()
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
        Task {
            let usage = await calculateActualStorageUsage()
            await MainActor.run {
                storageUsed = usage
            }
        }
    }
    
    private func calculateActualStorageUsage() async -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let resourceKeys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
            let enumerator = FileManager.default.enumerator(
                at: documentsPath,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles]
            )
            
            var totalSize: Int64 = 0
            
            if let enumerator = enumerator {
                for case let fileURL as URL in enumerator {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    if resourceValues.isDirectory != true {
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    }
                }
            }
            
            return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        } catch {
            return "Unable to calculate"
        }
    }
    
    private func clearCache() {
        // Clear temporary files and thumbnails
        print("Clearing cache...")
        calculateStorageUsed()
    }
    
    private func optimizeStorage() {
        // Optimize storage by removing unused files
        print("Optimizing storage...")
        calculateStorageUsed()
    }
    
    private func organizeByAuthor() {
        // Organize audiobooks by author
        print("Organizing by author...")
    }
    
    private func findDuplicates() {
        // Find duplicate audiobooks
        print("Finding duplicates...")
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("accentColor") private var accentColor: String = "blue"
    @AppStorage("useCompactPlayer") private var useCompactPlayer = false
    @AppStorage("showArtworkInLibrary") private var showArtworkInLibrary = true
    
    private let accentColors = [
        ("blue", "Blue", Color.blue),
        ("purple", "Purple", Color.purple),
        ("green", "Green", Color.green),
        ("orange", "Orange", Color.orange),
        ("red", "Red", Color.red),
        ("pink", "Pink", Color.pink)
    ]
    
    var body: some View {
        List {
            Section("Theme") {
                Picker("Appearance", selection: $colorScheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }
            
            Section("Accent Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(accentColors, id: \.0) { colorKey, colorName, color in
                        Button(action: {
                            accentColor = colorKey
                        }) {
                            VStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(accentColor == colorKey ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                
                                Text(colorName)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Interface") {
                Toggle("Compact Player", isOn: $useCompactPlayer)
                
                Toggle("Show Artwork in Library", isOn: $showArtworkInLibrary)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
