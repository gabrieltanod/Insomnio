//
//  LogHistoryView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 26/02/26.
//

import SwiftUI
import SwiftData

struct LogHistoryView: View {

    var viewModel: FlowViewModel

    @Environment(\.modelContext) private var modelContext

    // Fetch all logs sorted by date descending — filter in the view
    @Query(sort: \DailyLog.date, order: .reverse)
    private var allLogs: [DailyLog]

    /// Only logs from the past 7 days.
    private var logs: [DailyLog] {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        return allLogs.filter { $0.date > cutoff }
    }

    @State private var audioPlayer = AudioPlayerManager()
    @State private var expandedLogIDs: Set<UUID> = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if logs.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(logs) { log in
                        LogRowCard(
                            log: log,
                            isExpanded: expandedLogIDs.contains(log.id),
                            isPlaying: audioPlayer.currentlyPlayingID == log.id && audioPlayer.isPlaying,
                            onToggleTranscript: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedLogIDs.contains(log.id) {
                                        expandedLogIDs.remove(log.id)
                                    } else {
                                        expandedLogIDs.insert(log.id)
                                    }
                                }
                            },
                            onPlayPause: {
                                guard let url = log.audioFilePath else { return }
                                audioPlayer.play(url: url, id: log.id)
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: deleteLogs)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    audioPlayer.stop()
                    viewModel.resetFlow()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Done")
                    }
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.2))

            Text("No logs from the past 7 days.")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .foregroundStyle(Color(red: 0.5, green: 0.35, blue: 0.2))
        }
    }

    // MARK: - Delete

    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            let log = logs[index]
            if audioPlayer.currentlyPlayingID == log.id {
                audioPlayer.stop()
            }
            modelContext.delete(log)
        }
    }
}

// MARK: - Log Row Card

struct LogRowCard: View {

    let log: DailyLog
    let isExpanded: Bool
    let isPlaying: Bool
    let onToggleTranscript: () -> Void
    let onPlayPause: () -> Void

    private let textColor = Color(red: 0.9, green: 0.85, blue: 0.78)
    private let accentColor = Color(red: 0.85, green: 0.55, blue: 0.35)
    private let mutedColor = Color(red: 0.5, green: 0.35, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // MARK: - Date Header
            HStack {
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(mutedColor)

                Spacer()

                // Play button — only show if audio file exists
                if log.audioFilePath != nil {
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: - Extracted Thoughts
            if !log.extractedThoughts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(log.extractedThoughts, id: \.self) { thought in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(accentColor.opacity(0.6))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(thought)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(textColor)
                        }
                    }
                }
            }

            // MARK: - Transcript Toggle
            if !log.rawTranscript.isEmpty {
                Button(action: onToggleTranscript) {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Read Transcript")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                    }
                    .foregroundStyle(mutedColor)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Text(log.rawTranscript)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(textColor.opacity(0.7))
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#Preview {
    LogHistoryView(viewModel: FlowViewModel())
        .modelContainer(for: DailyLog.self, inMemory: true)
}
