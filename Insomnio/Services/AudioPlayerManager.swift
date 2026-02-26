//
//  AudioPlayerManager.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 26/02/26.
//

import Foundation
import AVFoundation

@Observable
final class AudioPlayerManager: NSObject, AVAudioPlayerDelegate {

    private(set) var isPlaying = false
    private(set) var currentlyPlayingID: UUID?

    private var audioPlayer: AVAudioPlayer?

    // MARK: - Playback

    func play(url: URL, id: UUID) {
        // If already playing this file, pause it
        if currentlyPlayingID == id, isPlaying {
            pause()
            return
        }

        // Stop any currently playing audio
        stop()

        do {
            // Configure audio session for playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingID = id
        } catch {
            stop()
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingID = nil
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentlyPlayingID = nil
    }
}
