//
//  IntroView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct IntroView: View {

    @Bindable var viewModel: FlowViewModel

    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            VStack(spacing: 48) {
                Spacer()

                Text("Somebody's having\ntrouble sleeping.")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.skipIntro()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                }

                Spacer()
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                contentOpacity = 1
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
