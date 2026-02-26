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

    @FocusState private var focusedIndex: Int?

    /// Tracks the previous focused index so we can clean up on blur.
    @State private var lastFocusedIndex: Int?

    // Shape colors
    private let shapeColors: [Color] = [
        Color(red: 0.80, green: 0.30, blue: 0.20),  // Warm red
        Color(red: 0.85, green: 0.55, blue: 0.35),  // Amber/Peach
        Color(red: 0.65, green: 0.42, blue: 0.25),  // Muted brown
    ]

    private let charLimit = 30

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)
                .opacity(focusedIndex != nil ? 0.4 : 1.0)
                .scaleEffect(focusedIndex != nil ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: focusedIndex)

            VStack(spacing: 24) {
                Spacer()

                // MARK: - Header

                Text(viewModel.extractedThoughts.isEmpty
                     ? "Anything else?"
                     : "Here's what's on your mind:")
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                    .opacity(headerOpacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.extractedThoughts.isEmpty)

                // MARK: - Dynamic Shapes

                thoughtSlots
                    .padding(.horizontal, 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.extractedThoughts.count)

                // MARK: - Add Button

                if viewModel.extractedThoughts.count < 3 {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.addThought()
                        }
                        // Focus the newly added empty thought
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedIndex = viewModel.extractedThoughts.count - 1
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundStyle(Color(red: 0.65, green: 0.42, blue: 0.25).opacity(0.6))
                    }
                    .transition(.opacity.combined(with: .scale))
                }

                Spacer()

                // MARK: - Buttons

                VStack(spacing: 16) {
                    Button {
                        viewModel.saveAndFinish(context: modelContext)
                    } label: {
                        Text("Yes, save for tomorrow")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.85, green: 0.55, blue: 0.35))
                            )
                    }
                    .disabled(viewModel.extractedThoughts.isEmpty)
                    .opacity(viewModel.extractedThoughts.isEmpty ? 0.5 : 1.0)

                    Button {
                        viewModel.discardAndFinish()
                    } label: {
                        Text("Yes, don't save it tho\nits just rambling")
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
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
            thoughtOpacities = Array(repeating: 0, count: viewModel.extractedThoughts.count)
            animateEntrance()
        }
        .onChange(of: focusedIndex) { oldValue, _ in
            // Auto-delete empty thoughts when focus leaves
            if let old = oldValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if viewModel.extractedThoughts.indices.contains(old),
                       viewModel.extractedThoughts[old]
                           .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.removeThought(at: old)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Dynamic Slot Layout

    @ViewBuilder
    private var thoughtSlots: some View {
        let thoughts = viewModel.extractedThoughts

        switch thoughts.count {
        case 0:
            EmptyView()

        case 1:
            thoughtCard(index: 0, shape: .circle)

        case 2:
            VStack(spacing: 20) {
                thoughtCard(index: 0, shape: .circle)
                thoughtCard(index: 1, shape: .roundedRect)
            }

        default: // 3
            VStack(spacing: 16) {
                thoughtCard(index: 0, shape: .circle)

                HStack(spacing: 16) {
                    thoughtCard(index: 1, shape: .roundedRect)
                    thoughtCard(index: 2, shape: .capsule)
                }
            }
        }
    }

    // MARK: - Shape Types

    private enum ShapeType {
        case circle, roundedRect, capsule
    }

    // MARK: - Thought Card

    @ViewBuilder
    private func thoughtCard(index: Int, shape: ShapeType) -> some View {
        let color = shapeColors[index % shapeColors.count]
        let isFocused = focusedIndex == index
        let isDimmed = focusedIndex != nil && !isFocused

        Group {
            switch shape {
            case .circle:
                cardTextField(index: index)
                    .padding(20)
                    .frame(minWidth: 140, minHeight: 140)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(Circle().fill(color.opacity(0.15)))
                    .overlay(Circle().strokeBorder(color, lineWidth: 1))
                    .clipShape(Circle())
                    .overlay(alignment: .topTrailing) {
                        deleteButton(index: index, color: color)
                            .offset(x: -100, y: 0)
                    }

            case .roundedRect:
                cardTextField(index: index)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(color, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        deleteButton(index: index, color: color)
                            .offset(x: 5, y: -5)
                    }

            case .capsule:
                cardTextField(index: index)
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(Capsule().fill(color.opacity(0.15)))
                    .overlay(Capsule().strokeBorder(color, lineWidth: 1))
                    .clipShape(Capsule())
                    .overlay(alignment: .topTrailing) {
                        deleteButton(index: index, color: color)
                            .offset(x: 5, y: -5)
                    }
            }
        }
        .scaleEffect(isDimmed ? 0.9 : 1.0)
        .opacity(isDimmed ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: focusedIndex)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Delete Button

    private func deleteButton(index: Int, color: Color) -> some View {
        Button {
            focusedIndex = nil
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.removeThought(at: index)
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(color.opacity(0.7))
                .background(
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 18, height: 18)
                )
        }
    }

    // MARK: - Card TextField

    private func cardTextField(index: Int) -> some View {
        TextField(
            "Tap to type…",
            text: Binding(
                get: {
                    guard viewModel.extractedThoughts.indices.contains(index) else { return "" }
                    return viewModel.extractedThoughts[index]
                },
                set: { newValue in
                    guard viewModel.extractedThoughts.indices.contains(index) else { return }
                    viewModel.extractedThoughts[index] = String(newValue.prefix(charLimit))
                }
            )
        )
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundStyle(Color(red: 0.9, green: 0.85, blue: 0.78))
        .multilineTextAlignment(.center)
        .focused($focusedIndex, equals: index)
        .submitLabel(.done)
        .onSubmit {
            focusedIndex = nil
        }
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
