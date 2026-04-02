//  Tempo - Zen Music Player
//  Ambient music playback for focus sessions

import Foundation
import SwiftUI
import Combine
import AVFoundation

final class ZenMusicPlayer: ObservableObject {
    static let shared = ZenMusicPlayer()

    @Published var isPlaying: Bool = false
    @Published var isLoading: Bool = false

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var settings: SettingsStore { SettingsStore.shared }

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

        guard let url = Bundle.main.url(forResource: "inner_peace", withExtension: "mp3") else {
            print("Failed to find inner_peace.mp3 in bundle")
            isLoading = false
            return
        }

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0.5

        NotificationCenter.default.addObserver(
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
        isPlaying = false
        isLoading = false
    }

    func getCurrentStationName() -> String {
        return "Inner Peace"
    }

    func nextStation() {}
}
