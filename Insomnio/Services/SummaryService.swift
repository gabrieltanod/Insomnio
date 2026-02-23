//
//  SummaryService.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import Foundation

// MARK: - Protocol

/// A service that takes a raw transcript and extracts key thoughts.
/// Designed for easy injection of CoreML or generative model implementations.
protocol SummaryServiceProtocol: Sendable {
    func summarize(transcript: String) async throws -> [String]
}

// MARK: - Mock Implementation

struct MockSummaryService: SummaryServiceProtocol {

    func summarize(transcript: String) async throws -> [String] {
        // Simulate processing delay
        try await Task.sleep(for: .seconds(2))

        return [
            "You're worried about tomorrow's meeting — specifically the presentation deck.",
            "There's unresolved tension from a conversation earlier today.",
            "You feel behind on a personal goal you set last month."
        ]
    }
}
