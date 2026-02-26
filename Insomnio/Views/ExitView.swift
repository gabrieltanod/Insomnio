//
//  ExitView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct ExitView: View {

    var viewModel: FlowViewModel

    @State private var textOpacity: Double = 0
    @State private var blackoutOpacity: Double = 0
    @State private var showHistoryButton = false

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            // Black overlay that fades in, covering the threads
            Color.black
                .ignoresSafeArea()
                .opacity(blackoutOpacity)

            VStack {
                Spacer()

                Text("We got you.\nNow go back to sleep.")
                    .font(.system(size: 25, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .padding(.horizontal)

                Spacer()

                // History button — fades in after 5 seconds
                if showHistoryButton {
                    Button {
                        viewModel.path.append(.history)
                    } label: {
                        Text("See previous logs")
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color(red: 0.72, green: 0.42, blue: 0.27)) // Muted Terracotta
                    }
                    .transition(.opacity)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 5.0)) {
                blackoutOpacity = 1
            }

            // Delayed history button reveal
            Task {
                try? await Task.sleep(for: .seconds(5))
                withAnimation(.easeInOut(duration: 3.0)) {
                    showHistoryButton = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExitView(viewModel: FlowViewModel())
}
