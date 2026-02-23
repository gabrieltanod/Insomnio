//
//  IntroView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct IntroView: View {

    @Bindable var viewModel: FlowViewModel

    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("Somebody's having\ntrouble sleeping.")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35)) // Warm amber
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.skipIntro()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                textOpacity = 1
            }
            viewModel.startIntroTimer()
        }
        .navigationBarBackButtonHidden(true)
    }
}
