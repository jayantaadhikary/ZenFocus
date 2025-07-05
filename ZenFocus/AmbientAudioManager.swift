//
//  AmbientAudioManager.swift
//  ZenFocus
//
//  Created by Jayanta Adhikary on 13/06/25.
//


import AVFoundation

class AmbientAudioManager: ObservableObject {
    static let shared = AmbientAudioManager()
    var player: AVAudioPlayer? // Make accessible for volume control
    @Published var currentVolume: Float = 0.5
    
    private init() {
        // Load saved volume setting
        currentVolume = UserDefaults.standard.float(forKey: "ambientVolume")
        if currentVolume == 0 { currentVolume = 0.5 } // Default value
    }
    
    func setVolume(_ volume: Float) {
        currentVolume = max(0.0, min(1.0, volume))
        player?.volume = currentVolume
    }

    func playSound(named name: String) {
        stop() // stop any previous playback

        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1
                player?.volume = currentVolume
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

