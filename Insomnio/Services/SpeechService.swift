//
//  SpeechService.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import AVFoundation
import Foundation
import Speech

/// Real-time offline speech-to-text using SFSpeechRecognizer + AVAudioEngine.
/// Simultaneously saves the audio to disk for later playback.
@Observable
final class SpeechService {

    // MARK: - Published State

    private(set) var isListening = false
    private(set) var transcript: String = ""

    /// URL of the most recently saved audio recording.
    private(set) var savedAudioURL: URL?

    // MARK: - Private Properties

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?

    // MARK: - Init

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // MARK: - Permissions

    /// Requests both Speech Recognition and Microphone permissions.
    /// Returns `true` only if both are granted.
    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechGranted else { return false }

        let micGranted = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        return micGranted
    }

    // MARK: - Dictation

    /// Starts real-time dictation. Updates `transcript` as speech is recognized.
    /// Audio is simultaneously saved to a .m4a file in the app's documents directory.
    func startDictation() throws {
        // Cancel any existing task
        stopDictation()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request with offline enforcement
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        // Reset transcript
        transcript = ""

        // Prepare audio file for saving
        let fileURL = Self.generateAudioFileURL()
        self.savedAudioURL = fileURL

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                self.transcript = result.bestTranscription.formattedString
            }

            if error != nil || (result?.isFinal ?? false) {
                self.cleanupAudioEngine()
            }
        }

        // Install audio tap — feed to recognizer AND write to file
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create the audio file with the same format as the input
        do {
            audioFile = try AVAudioFile(
                forWriting: fileURL,
                settings: recordingFormat.settings,
                commonFormat: recordingFormat.commonFormat,
                interleaved: recordingFormat.isInterleaved
            )
        } catch {
            // If file creation fails, still proceed with recognition (just no playback)
            audioFile = nil
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            // Feed to speech recognizer
            request.append(buffer)

            // Write to file for playback
            try? self?.audioFile?.write(from: buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    /// Stops dictation and cleans up resources.
    func stopDictation() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        cleanupAudioEngine()
    }

    // MARK: - Cleanup

    private func cleanupAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioFile = nil
        isListening = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - File Management

    /// Generates a unique file URL in the app's documents directory.
    private static func generateAudioFileURL() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioDir = documentsDir.appendingPathComponent("Recordings", isDirectory: true)

        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)

        let filename = "recording_\(Date.now.timeIntervalSince1970).caf"
        return audioDir.appendingPathComponent(filename)
    }
}

// MARK: - Errors

enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .permissionDenied:
            return "Speech recognition permission was denied."
        }
    }
}
