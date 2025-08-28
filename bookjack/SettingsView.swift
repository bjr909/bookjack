//
//  SettingsView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
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
