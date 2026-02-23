//
//  FlowViewModel.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import Foundation
import SwiftData

// MARK: - Flow Step

enum FlowStep: Hashable {
    case intro
    case record
    case review
    case exit
}

// MARK: - ViewModel

@Observable
final class FlowViewModel {

    // MARK: - Navigation

    var currentStep: FlowStep = .intro
    var path: [FlowStep] = []

    // MARK: - Intro

    private var introTimerTask: Task<Void, Never>?

    // MARK: - Recording

    private(set) var isRecording = false
    var transcript: String = ""

    // MARK: - Summary

    private(set) var extractedThoughts: [String] = []
    private(set) var isProcessing = false

    // MARK: - Dependencies

    private let audioRecorder: AudioRecorderService
    private let summaryService: any SummaryServiceProtocol

    // MARK: - Init

    init(
        audioRecorder: AudioRecorderService = AudioRecorderService(),
        summaryService: any SummaryServiceProtocol = MockSummaryService()
    ) {
        self.audioRecorder = audioRecorder
        self.summaryService = summaryService
    }

    // MARK: - Intro Logic

    /// Starts a 3-second timer that auto-advances to the record screen.
    func startIntroTimer() {
        introTimerTask?.cancel()
        introTimerTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            navigateTo(.record)
        }
    }

    /// Cancels the intro timer (used when the user taps early).
    func skipIntro() {
        introTimerTask?.cancel()
        navigateTo(.record)
    }

    // MARK: - Recording Logic

    func startRecording() {
        audioRecorder.startRecording()
        isRecording = true
        // In a real implementation, speech-to-text would populate `transcript`.
        transcript = "I can't stop thinking about work tomorrow. The presentation isn't ready and I keep replaying that awkward conversation with my manager. Also I haven't been to the gym in two weeks."
    }

    func stopRecordingAndProcess() {
        audioRecorder.stopRecording()
        isRecording = false
        isProcessing = true

        Task {
            do {
                let thoughts = try await summaryService.summarize(transcript: transcript)
                self.extractedThoughts = thoughts
                self.isProcessing = false
                navigateTo(.review)
            } catch {
                self.isProcessing = false
                // TODO: Handle error state
            }
        }
    }

    // MARK: - Review Logic

    /// Saves the session to SwiftData and navigates to exit.
    func saveAndFinish(context: ModelContext) {
        let log = DailyLog(
            rawTranscript: transcript,
            extractedThoughts: extractedThoughts,
            audioFilePath: audioRecorder.currentFileURL
        )
        context.insert(log)
        navigateTo(.exit)
    }

    /// Discards the session data and navigates to exit.
    func discardAndFinish() {
        transcript = ""
        extractedThoughts = []
        navigateTo(.exit)
    }

    // MARK: - Navigation

    private func navigateTo(_ step: FlowStep) {
        path.append(step)
    }

    /// Resets the entire flow back to the intro screen.
    func resetFlow() {
        path.removeAll()
        currentStep = .intro
        transcript = ""
        extractedThoughts = []
        isRecording = false
        isProcessing = false
    }
}
