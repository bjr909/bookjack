//
//  AudioPlayerManager.swift
//  bookjack
//
//  Created by Brett Ridenour on 8/26/25.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var sleepTimer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var volume: Float = 1.0
    @Published var isVolumeBoostEnabled = false
    @Published var currentAudiobook: Audiobook?
    @Published var currentChapter: Chapter?
    @Published var sleepTimerRemaining: TimeInterval = 0
    
    private let smartRewindSeconds: TimeInterval = 30
    
    override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
        setupInterruptionHandling()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        #if targetEnvironment(simulator)
        // iOS Simulator has limited audio session capabilities
        print("Running in simulator - using minimal audio session setup")
        do {
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            print("Simulator audio session setup failed (expected): \(error)")
            // Continue - audio will still work in simulator for basic playback
        }
        #else
        // Real device - full audio session setup
        do {
            // Try with full options first
            do {
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
                print("Full audio session setup successful")
            } catch {
                // Fallback to basic options if full options fail
                print("Full audio session setup failed, trying basic: \(error)")
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth])
            }
            
            // Activate the session
            try audioSession.setActive(true, options: [])
        } catch {
            print("Failed to set up audio session: \(error)")
            // Continue without audio session setup - the app can still work
        }
        #endif
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: event.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }
    
    func loadAudiobook(_ audiobook: Audiobook) {
        currentAudiobook = audiobook
        
        do {
            player = try AVAudioPlayer(contentsOf: audiobook.fileURL)
            player?.delegate = self
            player?.prepareToPlay()
            player?.currentTime = audiobook.currentPosition
            
            duration = player?.duration ?? 0
            currentTime = audiobook.currentPosition
            playbackRate = audiobook.playbackSpeed
            
            updateNowPlayingInfo()
            loadChapters()
            
        } catch {
            print("Failed to load audiobook: \(error)")
        }
    }
    
    private func loadChapters() {
        // This would typically parse M4B/M4A chapter metadata
        // For now, we'll use existing chapters from the model
        updateCurrentChapter()
    }
    
    private func updateCurrentChapter() {
        guard let audiobook = currentAudiobook else { return }
        
        currentChapter = audiobook.chapters.first { chapter in
            currentTime >= chapter.startTime && currentTime < chapter.endTime
        }
    }
    
    func play() {
        guard let player = player else { return }
        
        player.enableRate = true
        player.rate = playbackRate
        player.volume = isVolumeBoostEnabled ? min(volume * 2.0, 1.0) : volume
        player.play()
        
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
        
        currentAudiobook?.dateLastPlayed = Date()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
        
        saveCurrentPosition()
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        stopProgressTimer()
        cancelSleepTimer()
        
        saveCurrentPosition()
    }
    
    func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        player?.currentTime = clampedTime
        currentTime = clampedTime
        
        updateCurrentChapter()
        updateNowPlayingInfo()
        saveCurrentPosition()
    }
    
    func skipForward(_ seconds: TimeInterval = 30) {
        seek(to: currentTime + seconds)
    }
    
    func skipBackward(_ seconds: TimeInterval = 30) {
        // Smart rewind: go back extra if we just started playing
        let rewindTime = isPlaying && currentTime < smartRewindSeconds ? smartRewindSeconds : seconds
        seek(to: currentTime - rewindTime)
    }
    
    func jumpToChapter(_ chapter: Chapter) {
        seek(to: chapter.startTime)
    }
    
    func jumpToBeginning() {
        seek(to: 0)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(rate, 3.0))
        
        // Apply rate to player if it's currently playing
        if let player = player, player.isPlaying {
            player.enableRate = true
            player.rate = playbackRate
        }
        
        currentAudiobook?.playbackSpeed = playbackRate
        updateNowPlayingInfo()
    }
    
    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(volume, 1.0))
        player?.volume = isVolumeBoostEnabled ? min(self.volume * 2.0, 1.0) : self.volume
    }
    
    func toggleVolumeBoost() {
        isVolumeBoostEnabled.toggle()
        player?.volume = isVolumeBoostEnabled ? min(volume * 2.0, 1.0) : volume
    }
    
    func startSleepTimer(duration: TimeInterval) {
        cancelSleepTimer()
        sleepTimerRemaining = duration
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.sleepTimerRemaining -= 1
            
            if self.sleepTimerRemaining <= 0 {
                self.pause()
                self.cancelSleepTimer()
            }
        }
    }
    
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerRemaining = 0
    }
    
    private func startProgressTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            self.currentTime = player.currentTime
            self.updateCurrentChapter()
            
            // Auto-save progress every 30 seconds
            if Int(self.currentTime) % 30 == 0 {
                self.saveCurrentPosition()
            }
        }
    }
    
    private func stopProgressTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func saveCurrentPosition() {
        currentAudiobook?.currentPosition = currentTime
        
        // Mark as finished if within 30 seconds of the end
        if let audiobook = currentAudiobook, duration - currentTime < 30 {
            audiobook.isFinished = true
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let audiobook = currentAudiobook else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = audiobook.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = audiobook.author
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        
        if let artwork = audiobook.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }
        
        if let chapter = currentChapter {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = chapter.title
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopProgressTimer()
        
        if flag {
            currentAudiobook?.isFinished = true
            currentAudiobook?.currentPosition = duration
        }
        

    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        stopProgressTimer()
    }
}
