//
//  LibraryView.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AVFoundation

enum ImportError: Error, LocalizedError {
    case securityScopedResourceFailed
    case unsupportedFileType
    case metadataExtractionFailed
    case fileCopyFailed
    case databaseSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .securityScopedResourceFailed:
            return "Unable to access the selected file"
        case .unsupportedFileType:
            return "Unsupported file type"
        case .metadataExtractionFailed:
            return "Failed to extract file metadata"
        case .fileCopyFailed:
            return "Failed to copy file to app storage"
        case .databaseSaveFailed:
            return "Failed to save to library"
        }
    }
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Audiobook.dateAdded, order: .reverse) private var audiobooks: [Audiobook]
    @Query(sort: \AudiobookFolder.dateCreated, order: .reverse) private var allFolders: [AudiobookFolder]
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    
    let currentFolder: AudiobookFolder?
    
    init(currentFolder: AudiobookFolder? = nil) {
        self.currentFolder = currentFolder
    }
    
    @State private var showingImportOptions = false
    @State private var showingFilePicker = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateAdded
    @State private var showingOnlyUnfinished = false
    @State private var isImporting = false
    @State private var importStatus = ""
    @State private var showingFullPlayer = false
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var selectedAudiobook: Audiobook?
    @State private var showingFolderSelection = false
    @State private var selectedFolder: AudiobookFolder?
    
    // Computed properties for current folder contents
    private var folders: [AudiobookFolder] {
        if let currentFolder = currentFolder {
            return currentFolder.subfolders
        } else {
            return allFolders.filter { $0.parentFolder == nil }
        }
    }
    
    private var currentFolderAudiobooks: [Audiobook] {
        if let currentFolder = currentFolder {
            return currentFolder.audiobooks
        } else {
            return audiobooks.filter { $0.folder == nil }
        }
    }
    
    enum SortOrder: String, CaseIterable {
        case title = "Title"
        case author = "Author"
        case dateAdded = "Date Added"
        case progress = "Progress"
    }
    
    var filteredAudiobooks: [Audiobook] {
        var books = currentFolderAudiobooks
        
        // Filter by search text
        if !searchText.isEmpty {
            books = books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by completion status
        if showingOnlyUnfinished {
            books = books.filter { !$0.isFinished }
        }
        
        // Sort the books
        switch sortOrder {
        case .title:
            books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            books.sort { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .dateAdded:
            books.sort { $0.dateAdded > $1.dateAdded }
        case .progress:
            books.sort { $0.currentPosition > $1.currentPosition }
        }
        
        return books
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filter bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search audiobooks...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { showingOnlyUnfinished.toggle() }) {
                            Label(
                                showingOnlyUnfinished ? "Show All" : "Show Unfinished Only",
                                systemImage: showingOnlyUnfinished ? "eye" : "eye.slash"
                            )
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Import status
                if isImporting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(importStatus.isEmpty ? "Importing..." : importStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Audiobooks grid
                if filteredAudiobooks.isEmpty && folders.isEmpty {
                    Spacer()
                    EmptyLibraryView(showingImportOptions: $showingImportOptions)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 160), spacing: 16)
                        ], spacing: 16) {
                            // Show folders first
                            ForEach(folders) { folder in
                                NavigationLink(destination: LibraryView(currentFolder: folder)) {
                                    FolderCardView(folder: folder, selectedFolder: $selectedFolder)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Show audiobooks in current folder
                            ForEach(filteredAudiobooks) { audiobook in
                                AudiobookCardView(
                                    audiobook: audiobook,
                                    onMoveToFolder: { book in
                                        selectedAudiobook = book
                                        showingFolderSelection = true
                                    },
                                    onRemoveFromFolder: { book in
                                        removeAudiobookFromFolder(book)
                                    },
                                    onDelete: { book in
                                        deleteAudiobook(book)
                                    }
                                )
                                .onTapGesture {
                                    if audioPlayer.currentAudiobook?.id == audiobook.id {
                                        // If this book is already loaded, just resume if paused
                                        if !audioPlayer.isPlaying {
                                            audioPlayer.play()
                                        }
                                    } else {
                                        // Load new book (auto-plays) and show player
                                        audioPlayer.loadAudiobook(audiobook)
                                    }
                                    showingFullPlayer = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for mini player
                    }
                }
            }
            .navigationTitle(currentFolder?.name ?? "Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Import Options") {
                            showingImportOptions = true
                        }
                        Button("New Folder") {
                            showingNewFolderAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImportOptions) {
                ImportOptionsView(
                    showingFilePicker: $showingFilePicker
                )
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "m4b")!,
                    UTType(filenameExtension: "m4a")!,
                    UTType.mp3,
                    UTType(filenameExtension: "flac")!,
                    UTType.folder,
                    UTType.zip
                ],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }

            .fullScreenCover(isPresented: $showingFullPlayer) {
                FullPlayerView()
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Create") {
                    createNewFolder()
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingFolderSelection) {
                FolderSelectionView(
                    audiobook: selectedAudiobook,
                    folders: allFolders,
                    currentFolder: currentFolder,
                    onFolderSelected: { folder in
                        moveAudiobookToFolder(selectedAudiobook, to: folder)
                    },
                    onCreateNewFolder: { folderName in
                        createFolderAndMoveAudiobook(selectedAudiobook, folderName: folderName)
                    }
                )
            }

        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await importFiles(urls)
            }
        case .failure(let error):
            print("Failed to import files: \(error)")
            Task { @MainActor in
                importStatus = "Import failed: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }
    
    @MainActor
    private func importFiles(_ urls: [URL]) async {
        isImporting = true
        importStatus = "Preparing to import \(urls.count) item(s)..."
        
        var successCount = 0
        var failCount = 0
        
        for (index, url) in urls.enumerated() {
            importStatus = "Importing \(index + 1) of \(urls.count): \(url.lastPathComponent)"
            
            do {
                try await importItem(from: url)
                successCount += 1
                print("✅ Successfully imported: \(url.lastPathComponent)")
            } catch {
                failCount += 1
                print("❌ Failed to import: \(url.lastPathComponent) - \(error)")
            }
        }
        
        // Show final status
        if successCount > 0 {
            importStatus = "✅ Successfully imported \(successCount) audiobook(s)"
            if failCount > 0 {
                importStatus += " (\(failCount) failed)"
            }
        } else {
            importStatus = "❌ Import failed for all files"
        }
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isImporting = false
            self.importStatus = ""
        }
    }
    
    private func importItem(from url: URL) async throws {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource for: \(url.lastPathComponent)")
            throw ImportError.securityScopedResourceFailed
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .contentTypeKey])
            
            if resourceValues.isDirectory == true {
                // Handle folder import
                try await importFolder(from: url)
            } else if let contentType = resourceValues.contentType {
                if contentType.conforms(to: .zip) {
                    // Handle ZIP file
                    try await importZipFile(from: url)
                } else if isAudioFile(contentType) {
                    // Handle individual audio file
                    try await importAudioFile(from: url)
                } else {
                    throw ImportError.unsupportedFileType
                }
            } else {
                throw ImportError.unsupportedFileType
            }
        } catch {
            print("Failed to get resource values for \(url): \(error)")
            throw error
        }
    }
    
    private func isAudioFile(_ contentType: UTType) -> Bool {
        return contentType.conforms(to: .audio) ||
               contentType.identifier == "com.apple.m4a-audio" ||
               contentType.identifier == "com.audible.m4b" ||
               contentType.identifier == "org.xiph.flac"
    }
    
    private func importFolder(from folderURL: URL) async throws {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isDirectoryKey, .contentTypeKey])
            
            var audioFiles: [URL] = []
            
            // Find all audio files in the folder
            for fileURL in contents {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey, .contentTypeKey])
                
                if resourceValues.isDirectory != true,
                   let contentType = resourceValues.contentType,
                   isAudioFile(contentType) {
                    audioFiles.append(fileURL)
                }
            }
            
            if audioFiles.isEmpty {
                print("No audio files found in folder: \(folderURL.lastPathComponent)")
                return
            }
            
            // Sort audio files by name for proper order
            audioFiles.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            
            // If multiple files, create as separate audiobooks or combine based on naming
            if audioFiles.count == 1 {
                try await importAudioFile(from: audioFiles[0])
            } else {
                // Check if this looks like a multi-part audiobook
                let folderName = folderURL.lastPathComponent
                
                // For now, import each file separately
                // TODO: In the future, we could combine them into chapters
                for audioFile in audioFiles {
                    try await importAudioFile(from: audioFile, suggestedTitle: folderName)
                }
            }
            
        } catch {
            print("Failed to read folder contents: \(error)")
            throw error
        }
    }
    
    private func importZipFile(from zipURL: URL) async throws {
        // For now, just show a message that ZIP import is not yet implemented
        // TODO: Implement ZIP extraction and import
        print("ZIP file import not yet implemented: \(zipURL.lastPathComponent)")
        throw ImportError.unsupportedFileType
    }
    
    private func importAudioFile(from url: URL, suggestedTitle: String? = nil) async throws {
        print("🎵 Starting import of: \(url.lastPathComponent)")
        
        // Copy file to app's documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audiobooksPath = documentsPath.appendingPathComponent("Audiobooks")
        
        do {
            try FileManager.default.createDirectory(at: audiobooksPath, withIntermediateDirectories: true, attributes: nil)
            
            let fileName = url.lastPathComponent
            let destinationURL = audiobooksPath.appendingPathComponent(fileName)
            
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("📁 Removed existing file at destination")
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("📋 Successfully copied file to: \(destinationURL.path)")
            
            // Extract metadata and create audiobook
            let metadata = await extractMetadata(from: destinationURL)
            let title = metadata.title ?? suggestedTitle ?? fileName.replacingOccurrences(of: ".\(url.pathExtension)", with: "")
            
            print("🎯 Creating audiobook with title: '\(title)', author: '\(metadata.author ?? "Unknown Author")', duration: \(metadata.duration)s")
            
            let audiobook = Audiobook(
                title: title,
                author: metadata.author ?? "Unknown Author",
                fileURL: destinationURL,
                duration: metadata.duration
            )
            
            if let artworkData = metadata.artwork {
                audiobook.artworkData = artworkData
                print("🎨 Added artwork data (\(artworkData.count) bytes)")
            }
            
            audiobook.chapters = metadata.chapters
            print("📚 Added \(metadata.chapters.count) chapters")
            
            try await MainActor.run {
                print("💾 Inserting audiobook into model context...")
                modelContext.insert(audiobook)
                do {
                    try modelContext.save()
                    print("✅ Successfully imported and saved: \(title)")
                } catch {
                    print("❌ Failed to save audiobook to database: \(error)")
                    throw ImportError.databaseSaveFailed
                }
            }
            
        } catch {
            print("❌ Failed to import audiobook file \(url.lastPathComponent): \(error)")
            throw ImportError.fileCopyFailed
        }
    }
    
    private func extractMetadata(from url: URL) async -> (title: String?, author: String?, duration: TimeInterval, artwork: Data?, chapters: [Chapter]) {
        print("🔍 Extracting metadata from: \(url.lastPathComponent)")
        
        // Use modern AVURLAsset for iOS 18+
        let asset = AVURLAsset(url: url)
        
        var duration: TimeInterval = 0
        var title: String?
        var author: String?
        var artworkData: Data?
        var chapters: [Chapter] = []
        
        do {
            // Extract duration using modern API
            let assetDuration = try await asset.load(.duration)
            duration = assetDuration.seconds
            print("⏱️ Duration: \(duration) seconds")
            
            // Extract metadata using modern API
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                switch item.commonKey {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                    if let title = title {
                        print("📖 Title: \(title)")
                    }
                case .commonKeyArtist:
                    author = try? await item.load(.stringValue)
                    if let author = author {
                        print("✍️ Author: \(author)")
                    }
                case .commonKeyArtwork:
                    artworkData = try? await item.load(.dataValue)
                    if let artworkData = artworkData {
                        print("🎨 Found artwork: \(artworkData.count) bytes")
                    }
                default:
                    break
                }
            }
            
            // Extract chapters using modern API
            do {
                let chapterMetadata = try await asset.loadChapterMetadataGroups(
                    withTitleLocale: Locale.current, 
                    containingItemsWithCommonKeys: [.commonKeyTitle]
                )
                
                print("📚 Found \(chapterMetadata.count) chapter groups")
                
                for (index, group) in chapterMetadata.enumerated() {
                    let startTime = group.timeRange.start.seconds
                    let chapterDuration = group.timeRange.duration.seconds
                    
                    var chapterTitle = "Chapter \(index + 1)"
                    if let titleItem = group.items.first(where: { $0.commonKey == .commonKeyTitle }) {
                        chapterTitle = (try? await titleItem.load(.stringValue)) ?? chapterTitle
                    }
                    
                    let chapter = Chapter(title: chapterTitle, startTime: startTime, duration: chapterDuration)
                    chapters.append(chapter)
                    print("📄 Chapter \(index + 1): '\(chapterTitle)' at \(startTime)s")
                }
            } catch {
                print("⚠️ Failed to load chapter metadata: \(error)")
            }
            
        } catch {
            print("❌ Failed to load asset metadata: \(error)")
        }
        
        print("✅ Metadata extraction complete")
        return (title, author, duration, artworkData, chapters)
    }
    

    
    // MARK: - Folder Management
    private func createNewFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let folder = AudiobookFolder(
            name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines),
            parentFolder: currentFolder
        )
        modelContext.insert(folder)
        
        // Add to parent folder's subfolders if we're in a folder
        currentFolder?.subfolders.append(folder)
        
        do {
            try modelContext.save()
            print("✅ Created new folder: \(folder.name) in \(currentFolder?.name ?? "Library")")
        } catch {
            print("❌ Failed to create folder: \(error)")
        }
        
        newFolderName = ""
    }
    
    private func moveAudiobookToFolder(_ audiobook: Audiobook?, to folder: AudiobookFolder?) {
        guard let audiobook = audiobook else { return }
        
        // Remove from current folder if any
        if let currentFolder = audiobook.folder {
            if let index = currentFolder.audiobooks.firstIndex(where: { $0.id == audiobook.id }) {
                currentFolder.audiobooks.remove(at: index)
            }
        }
        
        // Set new folder relationship
        audiobook.folder = folder
        
        // Add to new folder's audiobooks array if folder is not nil
        if let folder = folder {
            // Check if audiobook is not already in the folder to avoid duplicates
            if !folder.audiobooks.contains(where: { $0.id == audiobook.id }) {
                folder.audiobooks.append(audiobook)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Moved \(audiobook.title) to folder: \(folder?.name ?? "Library")")
        } catch {
            print("❌ Failed to move audiobook: \(error)")
        }
        
        selectedAudiobook = nil
        showingFolderSelection = false
    }
    
    private func createFolderAndMoveAudiobook(_ audiobook: Audiobook?, folderName: String) {
        guard let audiobook = audiobook,
              !folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let folder = AudiobookFolder(name: folderName.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(folder)
        
        moveAudiobookToFolder(audiobook, to: folder)
    }
    
    private func removeAudiobookFromFolder(_ audiobook: Audiobook) {
        guard let folder = audiobook.folder else { return }
        
        // Remove from folder's audiobooks array
        if let index = folder.audiobooks.firstIndex(where: { $0.id == audiobook.id }) {
            folder.audiobooks.remove(at: index)
        }
        
        // Clear the audiobook's folder reference
        audiobook.folder = nil
        
        do {
            try modelContext.save()
            print("✅ Removed \(audiobook.title) from folder: \(folder.name)")
        } catch {
            print("❌ Failed to remove from folder: \(error)")
        }
    }
    
    private func deleteAudiobook(_ audiobook: Audiobook) {
        // Remove from folder if in one
        removeAudiobookFromFolder(audiobook)
        
        // Delete the physical file
        do {
            try FileManager.default.removeItem(at: audiobook.fileURL)
            print("🗑️ Deleted file: \(audiobook.fileURL.lastPathComponent)")
        } catch {
            print("⚠️ Failed to delete file: \(error)")
        }
        
        // Remove from database
        modelContext.delete(audiobook)
        
        do {
            try modelContext.save()
            print("✅ Deleted audiobook: \(audiobook.title)")
        } catch {
            print("❌ Failed to delete from database: \(error)")
        }
    }
}

struct EmptyLibraryView: View {
    @Binding var showingImportOptions: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Your Library is Empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import your first audiobook to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingImportOptions = true }) {
                Label("Import Audiobook", systemImage: "plus.circle.fill")
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

struct AudiobookCardView: View {
    let audiobook: Audiobook
    @StateObject private var audioPlayer = AudioPlayerManager.shared
    
    // Optional callbacks for folder operations
    let onMoveToFolder: ((Audiobook) -> Void)?
    let onRemoveFromFolder: ((Audiobook) -> Void)?
    let onDelete: ((Audiobook) -> Void)?
    
    init(audiobook: Audiobook, 
         onMoveToFolder: ((Audiobook) -> Void)? = nil,
         onRemoveFromFolder: ((Audiobook) -> Void)? = nil,
         onDelete: ((Audiobook) -> Void)? = nil) {
        self.audiobook = audiobook
        self.onMoveToFolder = onMoveToFolder
        self.onRemoveFromFolder = onRemoveFromFolder
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
                
                if let artwork = audiobook.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
                
                // Progress overlay
                if audiobook.progress > 0 && !audiobook.isFinished {
                    VStack {
                        Spacer()
                        ProgressView(value: audiobook.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                }
                
                // Finished badge
                if audiobook.isFinished {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .background(Color.white.clipShape(Circle()))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                
                // Currently playing indicator
                if audioPlayer.currentAudiobook?.id == audiobook.id {
                    VStack {
                        HStack {
                            Image(systemName: audioPlayer.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.7).clipShape(Circle()))
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            
            // Title and Author
            VStack(alignment: .leading, spacing: 2) {
                Text(audiobook.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(audiobook.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button(action: { 
                if audioPlayer.currentAudiobook?.id == audiobook.id {
                    // If this book is already loaded, just play/pause
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                } else {
                    // Load new book (auto-plays)
                    audioPlayer.loadAudiobook(audiobook)
                }
            }) {
                Label(
                    audioPlayer.currentAudiobook?.id == audiobook.id && audioPlayer.isPlaying ? "Pause" : "Play",
                    systemImage: audioPlayer.currentAudiobook?.id == audiobook.id && audioPlayer.isPlaying ? "pause.fill" : "play.fill"
                )
            }
            
            // Folder management options
            if let onMoveToFolder = onMoveToFolder {
                Button(action: { onMoveToFolder(audiobook) }) {
                    Label("Move to Folder", systemImage: "folder")
                }
            }
            
            if audiobook.folder != nil, let onRemoveFromFolder = onRemoveFromFolder {
                Button(action: { onRemoveFromFolder(audiobook) }) {
                    Label("Remove from Folder", systemImage: "folder.badge.minus")
                }
            }
            
            Button(action: { markAsFinished() }) {
                Label(audiobook.isFinished ? "Mark as Unfinished" : "Mark as Finished", 
                      systemImage: audiobook.isFinished ? "arrow.counterclockwise" : "checkmark")
            }
            
            Button(role: .destructive, action: { 
                if let onDelete = onDelete {
                    onDelete(audiobook)
                } else {
                    deleteAudiobook()
                }
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func markAsFinished() {
        audiobook.isFinished.toggle()
        if audiobook.isFinished {
            audiobook.currentPosition = audiobook.duration
        } else {
            audiobook.currentPosition = 0
        }
    }
    
    private func deleteAudiobook() {
        // TODO: Implement deletion with confirmation
    }
}

// MARK: - Folder Views
struct FolderCardView: View {
    let folder: AudiobookFolder
    @Binding var selectedFolder: AudiobookFolder?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Folder icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: folder.color))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Folder info
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("\(folder.audiobookCount) book\(folder.audiobookCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contextMenu {
            Button("Rename Folder") {
                // TODO: Add rename functionality
            }
            
            Button("Delete Folder", role: .destructive) {
                // TODO: Add delete folder functionality
            }
        }
    }
}

struct FolderSelectionView: View {
    let audiobook: Audiobook?
    let folders: [AudiobookFolder]
    let currentFolder: AudiobookFolder?
    let onFolderSelected: (AudiobookFolder?) -> Void
    let onCreateNewFolder: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    private var rootFolders: [AudiobookFolder] {
        return folders.filter { $0.parentFolder == nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Move to Folder") {
                    Button("📚 Library (No Folder)") {
                        onFolderSelected(nil)
                        dismiss()
                    }
                    
                    ForEach(rootFolders) { folder in
                        FolderHierarchyRow(
                            folder: folder,
                            level: 0,
                            currentFolder: currentFolder,
                            onFolderSelected: { selectedFolder in
                                onFolderSelected(selectedFolder)
                                dismiss()
                            }
                        )
                    }
                }
                
                Section {
                    Button("Create New Folder") {
                        showingNewFolderAlert = true
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Create") {
                    onCreateNewFolder(newFolderName)
                    newFolderName = ""
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

struct FolderHierarchyRow: View {
    let folder: AudiobookFolder
    let level: Int
    let currentFolder: AudiobookFolder?
    let onFolderSelected: (AudiobookFolder) -> Void
    
    private var indentation: CGFloat {
        return CGFloat(level * 20)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Main folder button
            Button(action: {
                onFolderSelected(folder)
            }) {
                HStack {
                    HStack {
                        // Indentation for nested folders
                        if level > 0 {
                            Spacer()
                                .frame(width: indentation)
                        }
                        
                        Image(systemName: "folder.fill")
                            .foregroundColor(Color(hex: folder.color))
                        
                        Text(folder.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(folder.directAudiobookCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .disabled(folder.id == currentFolder?.id)
            .opacity(folder.id == currentFolder?.id ? 0.5 : 1.0)
            
            // Subfolder buttons
            ForEach(folder.subfolders) { subfolder in
                FolderHierarchyRow(
                    folder: subfolder,
                    level: level + 1,
                    currentFolder: currentFolder,
                    onFolderSelected: onFolderSelected
                )
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Audiobook.self, inMemory: true)
}
