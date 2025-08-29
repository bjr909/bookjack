//
//  bookjackApp.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI
import SwiftData

@main
struct bookjackApp: App {
    @AppStorage("colorScheme") private var colorScheme: String = "system"
    @AppStorage("accentColor") private var accentColor: String = "blue"
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Audiobook.self,
            Chapter.self,
            PlaybackSession.self,
            AudiobookFolder.self,
        ])
        
        // Create the Application Support directory if it doesn't exist
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        do {
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create Application Support directory: \(error)")
        }
        
        let storeURL = appSupportURL.appendingPathComponent("BookJack.sqlite")
        let modelConfiguration = ModelConfiguration(url: storeURL, allowsSave: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Could not create ModelContainer: \(error)")
            // Fallback to in-memory store
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme == "system" ? nil : (colorScheme == "dark" ? .dark : .light))
                .accentColor(accentColorValue)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private var accentColorValue: Color {
        switch accentColor {
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        default: return .blue
        }
    }
}
