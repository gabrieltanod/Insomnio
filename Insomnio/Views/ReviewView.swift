//
//  ReviewView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct ReviewView: View {

    @Bindable var viewModel: FlowViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var headerOpacity: Double = 0
    @State private var thoughtOpacities: [Double] = [0, 0, 0]
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Text("Here's what's on your mind:")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .opacity(headerOpacity)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(viewModel.extractedThoughts.enumerated()), id: \.offset) { index, thought in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color(red: 0.8, green: 0.3, blue: 0.2))

                            Text(thought)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundStyle(Color(red: 0.75, green: 0.5, blue: 0.3))
                        }
                        .opacity(index < thoughtOpacities.count ? thoughtOpacities[index] : 1)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        viewModel.saveAndFinish(context: modelContext)
                    } label: {
                        Text("Yes, save for tomorrow")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.85, green: 0.55, blue: 0.35))
                            )
                    }

                    Button {
                        viewModel.discardAndFinish()
                    } label: {
                        Text("Yes, don't save it tho\nits just rambling")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.25))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                    }
                }
                .opacity(buttonsOpacity)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            animateEntrance()
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Staggered Animation

    private func animateEntrance() {
        withAnimation(.easeIn(duration: 0.6)) {
            headerOpacity = 1
        }

        for index in viewModel.extractedThoughts.indices {
            let delay = 0.6 + Double(index) * 0.4
            withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                if index < thoughtOpacities.count {
                    thoughtOpacities[index] = 1
                }
            }
        }

        let buttonsDelay = 0.6 + Double(viewModel.extractedThoughts.count) * 0.4 + 0.3
        withAnimation(.easeIn(duration: 0.5).delay(buttonsDelay)) {
            buttonsOpacity = 1
        }
    }
}
