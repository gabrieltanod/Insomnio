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

// MARK: - Input Mode

enum InputMode {
    case voice
    case text
}

// MARK: - ViewModel

@Observable
final class FlowViewModel {

    // MARK: - Navigation

    var currentStep: FlowStep = .intro
    var path: [FlowStep] = []

    // MARK: - Input Mode

    var inputMode: InputMode = .voice

    // MARK: - Intro

    /// Advances past the intro screen to the record screen.
    func skipIntro() {
        navigateTo(.record)
    }

    // MARK: - Recording State

    private(set) var isRecording = false
    var transcript: String = ""

    // MARK: - Summary

    private(set) var extractedThoughts: [String] = []
    private(set) var isProcessing = false

    // MARK: - Dependencies

    let speechService: SpeechService
    private let summaryService: any SummaryServiceProtocol

    // MARK: - Init

    init(
        speechService: SpeechService = SpeechService(),
        summaryService: any SummaryServiceProtocol = BrainDumpService()
    ) {
        self.speechService = speechService
        self.summaryService = summaryService
    }

    // MARK: - Voice Recording

    func startRecording() {
        do {
            try speechService.startDictation()
            isRecording = true
        } catch {
            // Fallback: stay on record screen, user can retry or switch to text
            isRecording = false
        }
    }

    func stopRecordingAndProcess() {
        speechService.stopDictation()
        transcript = speechService.transcript
        isRecording = false
        processTranscript()
    }

    // MARK: - Text Input

    func submitTextAndProcess() {
        processTranscript()
    }

    // MARK: - Processing Pipeline

    private func processTranscript() {
        isProcessing = true

        Task {
            do {
                let thoughts = try await summaryService.summarize(transcript: transcript)
                self.extractedThoughts = thoughts

                // Hold the freeze for 1.5 seconds so the animation visually decelerates
                try await Task.sleep(for: .seconds(1.5))

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
            extractedThoughts: extractedThoughts
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
        inputMode = .voice
    }

    // MARK: - Preview Helpers

    #if DEBUG
    static var previewWithThoughts: FlowViewModel {
        let vm = FlowViewModel()
        vm.extractedThoughts = [
            "email professor",
            "finish project",
            "stress"
        ]
        return vm
    }

    static var previewSingleThought: FlowViewModel {
        let vm = FlowViewModel()
        vm.extractedThoughts = ["sleep"]
        return vm
    }
    #endif
}
