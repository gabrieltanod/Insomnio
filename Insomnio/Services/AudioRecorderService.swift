//
//  AudioRecorderService.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import AVFoundation
import Foundation

@Observable
final class AudioRecorderService {

    // MARK: - Published State

    private(set) var isRecording = false
    private(set) var currentFileURL: URL?

    // MARK: - Permission

    /// Requests microphone permission. Returns `true` if granted.
    func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - File Path

    /// Creates a unique `.m4a` file path inside the app's Documents directory.
    private func createFilePath() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "insomnio_\(UUID().uuidString).m4a"
        return docs.appendingPathComponent(fileName)
    }

    // MARK: - Recording (Stubbed)

    /// Starts a recording session. Currently stubbed — sets state only.
    func startRecording() {
        let url = createFilePath()
        currentFileURL = url
        isRecording = true
        // TODO: Initialize AVAudioRecorder with `url` and begin recording.
    }

    /// Stops the current recording session. Currently stubbed — sets state only.
    func stopRecording() {
        isRecording = false
        // TODO: Stop AVAudioRecorder and finalize the file.
    }
}
