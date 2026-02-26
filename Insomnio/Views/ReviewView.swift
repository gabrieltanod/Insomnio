//
//  ReviewView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI
import SwiftData

struct ReviewView: View {

    @Bindable var viewModel: FlowViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var headerOpacity: Double = 0
    @State private var thoughtOpacities: [Double] = []
    @State private var buttonsOpacity: Double = 0

    // Shape colors
    private let shapeColors: [Color] = [
        Color(red: 0.80, green: 0.30, blue: 0.20),  // Warm red
        Color(red: 0.85, green: 0.55, blue: 0.35),  // Amber/Peach
        Color(red: 0.65, green: 0.42, blue: 0.25),  // Muted brown
    ]

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            VStack(spacing: 28) {
                Spacer()

                Text("Here's what's on your mind:")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .opacity(headerOpacity)

                // MARK: - Dynamic Shapes

                thoughtShapes
                    .padding(.horizontal, 24)

                Spacer()

                // MARK: - Buttons

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
            // Initialize opacities based on actual count
            thoughtOpacities = Array(repeating: 0, count: viewModel.extractedThoughts.count)
            animateEntrance()
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Thought Shapes

    @ViewBuilder
    private var thoughtShapes: some View {
        let thoughts = viewModel.extractedThoughts

        switch thoughts.count {
        case 1:
            // Single shape centered
            thoughtShape(index: 0, thought: thoughts[0], shape: .circle)

        case 2:
            // Two shapes evenly spaced
            VStack(spacing: 20) {
                thoughtShape(index: 0, thought: thoughts[0], shape: .circle)
                thoughtShape(index: 1, thought: thoughts[1], shape: .roundedRect)
            }

        case 3:
            // Three shapes in vertical layout
            VStack(spacing: 16) {
                thoughtShape(index: 0, thought: thoughts[0], shape: .circle)

                HStack(spacing: 16) {
                    thoughtShape(index: 1, thought: thoughts[1], shape: .roundedRect)
                    thoughtShape(index: 2, thought: thoughts[2], shape: .capsule)
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Shape Types

    private enum ShapeType {
        case circle, roundedRect, capsule
    }

    @ViewBuilder
    private func thoughtShape(index: Int, thought: String, shape: ShapeType) -> some View {
        let opacity = index < thoughtOpacities.count ? thoughtOpacities[index] : 1.0
        let color = shapeColors[index % shapeColors.count]

        Group {
            switch shape {
            case .circle:
                Text(thought)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.9, green: 0.85, blue: 0.78))
                    .multilineTextAlignment(.center)
                    .padding(24)
                    .frame(minWidth: 140, minHeight: 140)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay(
                                Circle()
                                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
                            )
                    )

            case .roundedRect:
                Text(thought)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.9, green: 0.85, blue: 0.78))
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
                            )
                    )

            case .capsule:
                Text(thought)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color(red: 0.9, green: 0.85, blue: 0.78))
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(color.opacity(0.4), lineWidth: 1)
                            )
                    )
            }
        }
        .opacity(opacity)
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

#Preview {
    ReviewView(viewModel: .previewWithThoughts)
        .modelContainer(for: DailyLog.self, inMemory: true)
}
