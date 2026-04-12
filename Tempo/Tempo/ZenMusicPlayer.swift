//  Tempo - Zen Music Player
//  Ambient music playback for focus sessions

import Foundation
import SwiftUI
import Combine
import AVFoundation

struct ZenTrack {
    let fileName: String
    let displayName: String
    let artist: String
}

final class ZenMusicPlayer: ObservableObject {
    static let shared = ZenMusicPlayer()

    static let tracks: [ZenTrack] = [
        ZenTrack(fileName: "inner_peace", displayName: "Inner Peace", artist: "Grand_Project"),
        ZenTrack(fileName: "zen_moods", displayName: "Zen Moods", artist: "djovan"),
        ZenTrack(fileName: "zen_garden", displayName: "Zen Garden", artist: "Grand_Project"),
    ]

    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentTrackIndex: Int = 0

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var endObserver: NSObjectProtocol?
    private var settings: SettingsStore { SettingsStore.shared }

    var currentTrack: ZenTrack {
        Self.tracks[currentTrackIndex]
    }

    private init() {}

    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    func play() {
        guard !isPlaying else { return }

        isLoading = true

        let track = currentTrack
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: "mp3") else {
            print("Failed to find \(track.fileName).mp3 in bundle")
            isLoading = false
            return
        }

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0.5

        // Remove any previous observer
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        player?.play()
        isPlaying = true
        isLoading = false
    }

    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        isPlaying = false
        isLoading = false
    }

    func getCurrentStationName() -> String {
        return currentTrack.displayName
    }

    func nextStation() {
        let wasPlaying = isPlaying
        if isPlaying { stop() }
        currentTrackIndex = (currentTrackIndex + 1) % Self.tracks.count
        if wasPlaying { play() }
    }
}
