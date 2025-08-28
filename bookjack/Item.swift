//
//  Models.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import Foundation
import SwiftData
import UIKit

@Model
final class Audiobook {
    var id: UUID
    var title: String
    var author: String
    var duration: TimeInterval
    var currentPosition: TimeInterval
    var isFinished: Bool
    var dateAdded: Date
    var dateLastPlayed: Date?
    var artworkData: Data?
    var fileURL: URL
    var playbackSpeed: Float
    var chapters: [Chapter]
    var playlists: [Playlist]
    var folder: AudiobookFolder?
    
    init(title: String, author: String, fileURL: URL, duration: TimeInterval = 0) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.fileURL = fileURL
        self.duration = duration
        self.currentPosition = 0
        self.isFinished = false
        self.dateAdded = Date()
        self.dateLastPlayed = nil
        self.artworkData = nil
        self.playbackSpeed = 1.0
        self.chapters = []
        self.playlists = []
        self.folder = nil
    }
    
    var artwork: UIImage? {
        guard let artworkData = artworkData else { return nil }
        return UIImage(data: artworkData)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentPosition / duration
    }
    
    var remainingTime: TimeInterval {
        return duration - currentPosition
    }
}

@Model
final class Chapter {
    var id: UUID
    var title: String
    var startTime: TimeInterval
    var duration: TimeInterval
    var audiobook: Audiobook?
    
    init(title: String, startTime: TimeInterval, duration: TimeInterval) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.duration = duration
    }
    
    var endTime: TimeInterval {
        return startTime + duration
    }
}

@Model
final class Playlist {
    var id: UUID
    var name: String
    var dateCreated: Date
    var audiobooks: [Audiobook]
    var currentIndex: Int
    var isAutoPlay: Bool
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.audiobooks = []
        self.currentIndex = 0
        self.isAutoPlay = true
    }
    
    var currentAudiobook: Audiobook? {
        guard currentIndex >= 0 && currentIndex < audiobooks.count else { return nil }
        return audiobooks[currentIndex]
    }
    
    var nextUnfinishedAudiobook: Audiobook? {
        return audiobooks.first { !$0.isFinished }
    }
}

@Model
final class AudiobookFolder {
    var id: UUID
    var name: String
    var dateCreated: Date
    var audiobooks: [Audiobook]
    var color: String // Hex color for folder
    var parentFolder: AudiobookFolder?
    var subfolders: [AudiobookFolder]
    
    init(name: String, color: String = "#007AFF", parentFolder: AudiobookFolder? = nil) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.audiobooks = []
        self.color = color
        self.parentFolder = parentFolder
        self.subfolders = []
    }
    
    var audiobookCount: Int {
        return audiobooks.count + subfolders.reduce(0) { $0 + $1.audiobookCount }
    }
    
    var directAudiobookCount: Int {
        return audiobooks.count
    }
    
    var totalDuration: TimeInterval {
        return audiobooks.reduce(0) { $0 + $1.duration } + subfolders.reduce(0) { $0 + $1.totalDuration }
    }
    
    var isRootFolder: Bool {
        return parentFolder == nil
    }
}

@Model
final class PlaybackSession {
    var id: UUID
    var audiobook: Audiobook?
    var startTime: TimeInterval
    var endTime: TimeInterval
    var date: Date
    
    init(audiobook: Audiobook, startTime: TimeInterval, endTime: TimeInterval) {
        self.id = UUID()
        self.audiobook = audiobook
        self.startTime = startTime
        self.endTime = endTime
        self.date = Date()
    }
    
    var duration: TimeInterval {
        return endTime - startTime
    }
}
