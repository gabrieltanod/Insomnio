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
    @State private var pulseAnimates = false
    @FocusState private var isTextFieldFocused: Bool

    // Circadian color
    private let terracotta = Color(red: 0.72, green: 0.42, blue: 0.27) // #B86A44

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            VStack(spacing: 32) {

                Spacer()

                // MARK: - Header

                Text("Let me hear about it.")
                    .font(.system(size: 25, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                if viewModel.isProcessing {

                    // MARK: - Processing State

                    ProgressView()
                        .tint(Color(red: 0.85, green: 0.55, blue: 0.35))
                        .scaleEffect(1.5)

                    Text("Processing your thoughts…")
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.white)

                } else if viewModel.inputMode == .voice {

                    // MARK: - Voice Mode

                    voiceModeContent

                } else {

                    // MARK: - Text Mode

                    textModeContent
                }

                Spacer()

                // MARK: - Input Mode Toggle

                if !viewModel.isProcessing && !viewModel.isRecording {
                    inputModeToggle
                        .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1
            }
        }
        .onChange(of: viewModel.isRecording) { _, isNowRecording in
            if isNowRecording {
                // Start the breathing pulse
                pulseAnimates = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: false)) {
                        pulseAnimates = true
                    }
                }
            } else {
                // Stop the pulse immediately
                withAnimation(.linear(duration: 0.1)) {
                    pulseAnimates = false
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Voice Mode Content

    private var voiceModeContent: some View {
        VStack(spacing: 24) {
            // Live transcript display
            if viewModel.isRecording {
                Text(viewModel.speechService.transcript.isEmpty
                     ? "Listening…"
                     : viewModel.speechService.transcript)
                    .font(.system(size: 15, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.25).opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineLimit(4)
                    .transition(.opacity)
            }

            // MARK: - Record Button with Breathing Pulse

            ZStack {
                // Breathing pulse ring — expands over 4 seconds
                Circle()
                    .stroke(terracotta.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimates ? 2.0 : 1.0)
                    .opacity(pulseAnimates ? 0.0 : 0.4)
                    .opacity(viewModel.isRecording ? 1 : 0)

                // Morphing button: Circle → Rounded Square
                Button {
                    handleRecordTap()
                } label: {
                    RoundedRectangle(cornerRadius: viewModel.isRecording ? 6 : 32)
                        .fill(terracotta)
                        .frame(
                            width: viewModel.isRecording ? 32 : 64,
                            height: viewModel.isRecording ? 32 : 64
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isRecording)
                }
            }

            // Hint text — only when idle
            if !viewModel.isRecording {
                Text("Tap to speak")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRecording)
    }

    // MARK: - Record Tap Handler

    private func handleRecordTap() {
        if viewModel.isRecording {
            // Tap 2: Stop → process → navigate
            viewModel.stopRecordingAndProcess()
        } else {
            // Tap 1: Start recording
            viewModel.startRecording()
        }
    }

    // MARK: - Text Mode Content

    private var textModeContent: some View {
        VStack(spacing: 20) {
            TextEditor(text: $viewModel.transcript)
                .font(.system(size: 16, weight: .regular, design: .monospaced))
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
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    }
                }
                .onAppear {
                    isTextFieldFocused = true
                }

            Text("Type what's on your mind, then tap Done.")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
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
}

#Preview {
    RecordView(viewModel: FlowViewModel())
}
