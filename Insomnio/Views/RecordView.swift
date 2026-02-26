//
//  RecordView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct RecordView: View {

    @Bindable var viewModel: FlowViewModel

    @State private var textOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            VStack(spacing: 32) {

                Spacer()

                // MARK: - Header

                Text(viewModel.inputMode == .voice
                     ? "Let me hear about it."
                     : "Let me read about it.")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.inputMode)

                if viewModel.isProcessing {

                    // MARK: - Processing State

                    ProgressView()
                        .tint(Color(red: 0.85, green: 0.55, blue: 0.35))
                        .scaleEffect(1.5)

                    Text("Processing your thoughts…")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Color(red: 0.7, green: 0.45, blue: 0.25))

                } else if viewModel.inputMode == .voice {

                    // MARK: - Voice Mode

                    voiceModeContent

                } else {

                    // MARK: - Text Mode

                    textModeContent
                }

                Spacer()

                // MARK: - Input Mode Toggle

                if !viewModel.isProcessing {
                    inputModeToggle
                        .padding(.bottom, 48)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(longPressGesture)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Voice Mode Content

    private var voiceModeContent: some View {
        VStack(spacing: 24) {
            // Live transcript display
            if !viewModel.transcript.isEmpty || viewModel.isRecording {
                Text(viewModel.isRecording
                     ? (viewModel.speechService.transcript.isEmpty
                        ? "Listening…"
                        : viewModel.speechService.transcript)
                     : "")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.25).opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineLimit(4)
            }

            // Pulsing record indicator
            ZStack {
                if viewModel.isRecording {
                    Circle()
                        .fill(Color(red: 0.8, green: 0.3, blue: 0.2).opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                }

                Circle()
                    .fill(viewModel.isRecording
                          ? Color(red: 0.8, green: 0.3, blue: 0.2)
                          : Color(red: 0.85, green: 0.55, blue: 0.35))
                    .frame(width: 60, height: 60)

                Image(systemName: "mic.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.black.opacity(0.8))
            }

            Text(viewModel.isRecording ? "Release to stop" : "Hold to speak")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.25))
        }
    }

    // MARK: - Text Mode Content

    private var textModeContent: some View {
        VStack(spacing: 20) {
            TextEditor(text: $viewModel.transcript)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .frame(height: 160)
                .padding(.horizontal, 32)
                .focused($isTextFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false
                            guard !viewModel.transcript
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty else { return }
                            viewModel.submitTextAndProcess()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    }
                }
                .onAppear {
                    isTextFieldFocused = true
                }

            Text("Type what's on your mind, then tap Done.")
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 0.5, green: 0.35, blue: 0.2))
        }
    }

    // MARK: - Input Mode Toggle

    private var inputModeToggle: some View {
        HStack(spacing: 24) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.inputMode = .voice
                }
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        viewModel.inputMode == .voice
                        ? Color(red: 0.85, green: 0.55, blue: 0.35)
                        : Color(red: 0.4, green: 0.3, blue: 0.2)
                    )
            }

            Rectangle()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.15))
                .frame(width: 1, height: 20)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.inputMode = .text
                }
            } label: {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        viewModel.inputMode == .text
                        ? Color(red: 0.85, green: 0.55, blue: 0.35)
                        : Color(red: 0.4, green: 0.3, blue: 0.2)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Long Press Gesture

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .onChanged { _ in
                guard viewModel.inputMode == .voice,
                      !viewModel.isProcessing, !viewModel.isRecording else { return }
                viewModel.startRecording()
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseScale = 1.6
                }
            }
            .onEnded { _ in
                guard viewModel.isRecording else { return }
                pulseScale = 1.0
                viewModel.stopRecordingAndProcess()
            }
    }
}

#Preview {
    RecordView(viewModel: FlowViewModel())
}
