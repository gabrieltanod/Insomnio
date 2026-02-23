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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Let me hear about it.")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)

                if viewModel.isProcessing {
                    ProgressView()
                        .tint(Color(red: 0.85, green: 0.55, blue: 0.35))
                        .scaleEffect(1.5)

                    Text("Processing your thoughts…")
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Color(red: 0.7, green: 0.45, blue: 0.25))
                } else {
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
                    }

                    Text(viewModel.isRecording ? "Release to stop" : "Hold to speak")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.25))
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in
                    guard !viewModel.isProcessing else { return }
                    if !viewModel.isRecording {
                        viewModel.startRecording()
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseScale = 1.6
                        }
                    }
                }
                .onEnded { _ in
                    guard viewModel.isRecording else { return }
                    pulseScale = 1.0
                    viewModel.stopRecordingAndProcess()
                }
        )
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
