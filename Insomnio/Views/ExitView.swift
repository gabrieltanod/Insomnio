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

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            // Black overlay that fades in over 8 seconds, covering the threads
            Color.black
                .ignoresSafeArea()
                .opacity(blackoutOpacity)

            Text("We got you.\nNow go back to sleep.")
                .font(.system(size: 25, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
                .padding(.horizontal)

        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 5.0)) {
                blackoutOpacity = 1
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ExitView(viewModel: FlowViewModel())
}
