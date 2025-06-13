//
//  AmbientAudioManager.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 13/06/25.
//


import AVFoundation

class AmbientAudioManager: ObservableObject {
    static let shared = AmbientAudioManager()
    private var player: AVAudioPlayer?

    func playSound(named name: String) {
        stop() // stop any previous playback

        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = 0.5
                player?.play()
            } catch {
                print("Failed to play sound \(name): \(error.localizedDescription)")
            }
        } else {
            print("Audio file \(name) not found in bundle.")
        }
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}

