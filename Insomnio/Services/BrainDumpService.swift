//
//  BrainDumpService.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import Foundation
import NaturalLanguage

/// On-device NLP extraction using Apple's NLTagger.
/// Conforms to `SummaryServiceProtocol` as a drop-in replacement for the mock.
struct BrainDumpService: SummaryServiceProtocol {

    // MARK: - Constants

    private let maxItems = 3

    /// Common stopwords to skip during noun extraction.
    private let stopwords: Set<String> = [
        "i", "me", "my", "we", "our", "you", "your", "he", "she", "it",
        "they", "them", "the", "a", "an", "and", "or", "but", "in", "on",
        "at", "to", "for", "of", "with", "is", "am", "are", "was", "were",
        "be", "been", "being", "have", "has", "had", "do", "does", "did",
        "will", "would", "could", "should", "may", "might", "can", "shall",
        "not", "no", "so", "if", "then", "that", "this", "there", "here",
        "what", "which", "who", "whom", "how", "when", "where", "why",
        "all", "each", "every", "some", "any", "few", "more", "most",
        "just", "also", "very", "really", "about", "up", "out", "its",
        "thing", "things", "stuff", "lot", "lots", "way", "much", "many"
    ]

    // MARK: - SummaryServiceProtocol

    func summarize(transcript: String) async throws -> [String] {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // Pass 1: Task Hunt — find Verb + Noun pairs
        var tasks = taskHunt(in: trimmed)

        // Pass 2: Rant Fallback — fill remaining slots with prominent nouns
        if tasks.count < maxItems {
            let keywords = rantFallback(in: trimmed, excluding: tasks)
            let remaining = maxItems - tasks.count
            tasks.append(contentsOf: keywords.prefix(remaining))
        }

        return tasks
    }

    // MARK: - Pass 1: Task Hunt

    /// Scans for Verb + Noun pairs that form actionable tasks.
    private func taskHunt(in text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        // Collect all tagged tokens
        var tokens: [(word: String, tag: NLTag, range: Range<String.Index>)] = []

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            if let tag = tag {
                let word = String(text[range])
                tokens.append((word: word, tag: tag, range: range))
            }
            return true
        }

        var tasks: [String] = []
        var usedIndices: Set<Int> = []

        for i in 0..<tokens.count where !usedIndices.contains(i) {
            let token = tokens[i]

            // Look for a Verb
            guard token.tag == .verb else { continue }

            // Search forward for a Noun within the next 2 tokens
            let searchEnd = min(i + 3, tokens.count)
            for j in (i + 1)..<searchEnd where !usedIndices.contains(j) {
                if tokens[j].tag == .noun {
                    let phrase = "\(token.word) \(tokens[j].word)".lowercased()
                    tasks.append(phrase)
                    usedIndices.formUnion([i, j])
                    break
                }
            }

            if tasks.count >= maxItems { break }
        }

        return tasks
    }

    // MARK: - Pass 2: Rant Fallback

    /// Extracts the most frequent meaningful nouns as keyword summaries.
    private func rantFallback(in text: String, excluding existing: [String]) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var nounCounts: [String: Int] = [:]

        // Flatten existing tasks into a set of used words
        let usedWords = Set(existing.flatMap { $0.split(separator: " ").map { String($0).lowercased() } })

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            guard let tag = tag, tag == .noun else { return true }

            let word = String(text[range]).lowercased()

            // Skip short words, stopwords, and already-used words
            guard word.count > 2,
                  !stopwords.contains(word),
                  !usedWords.contains(word) else { return true }

            nounCounts[word, default: 0] += 1
            return true
        }

        // Sort by frequency (descending), then alphabetically for stability
        let sorted = nounCounts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key < rhs.key
            }
            .map(\.key)

        return Array(sorted)
    }
}
