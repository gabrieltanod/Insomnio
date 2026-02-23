//
//  DailyLog.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    var id: UUID
    var date: Date
    var rawTranscript: String
    var extractedThoughts: [String]
    var audioFilePath: URL?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        rawTranscript: String = "",
        extractedThoughts: [String] = [],
        audioFilePath: URL? = nil
    ) {
        self.id = id
        self.date = date
        self.rawTranscript = rawTranscript
        self.extractedThoughts = extractedThoughts
        self.audioFilePath = audioFilePath
    }
}
