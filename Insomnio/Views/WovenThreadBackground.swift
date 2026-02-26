//
//  WovenThreadBackground.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct WovenThreadBackground: View {

    var viewModel: FlowViewModel

    // Smooth interpolation value: 0 = idle, 1 = active
    @State private var intensity: Double = 0

    // Animation speed multiplier: 1.0 = normal, 0.0 = frozen
    @State private var animationSpeed: Double = 1.0

    // Thread configuration
    private let threadCount = 6
    private let pointsPerThread = 80

    // Colors
    private let idleColor = Color(red: 0.54, green: 0.17, blue: 0.02)   // #8A2B06
    private let activeColor = Color(red: 0.80, green: 0.33, blue: 0.00) // #CC5500

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let currentIntensity = intensity
                let currentSpeed = animationSpeed

                // Interpolate speed: idle = 0.3, active = 0.9, then modulated by animationSpeed
                let speed = (0.3 + currentIntensity * 0.6) * currentSpeed

                // Interpolate stroke width: idle = 2, active = 2.5
                let strokeWidth = 2.0 + currentIntensity * 0.5

                // Interpolate opacity: idle = 0.6, active = 0.85
                let opacity = 0.6 + currentIntensity * 0.25

                // Interpolate color
                let blendedColor = blendColor(
                    from: idleColor,
                    to: activeColor,
                    t: currentIntensity
                )

                for i in 0..<threadCount {
                    let path = buildSquiggle(
                        index: i,
                        time: time,
                        speed: speed,
                        center: center,
                        size: size
                    )

                    context.opacity = opacity
                    context.stroke(
                        path,
                        with: .color(blendedColor),
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
        }
        .ignoresSafeArea()
        .background(.black)
        .onChange(of: viewModel.isRecording) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                intensity = newValue ? 1.0 : 0.0
            }
        }
        .onChange(of: viewModel.isProcessing) { _, newValue in
            if newValue {
                // Decelerate to frozen over 1.2 seconds
                withAnimation(.easeOut(duration: 1.2)) {
                    animationSpeed = 0.0
                }
            } else {
                // Restore normal speed
                withAnimation(.easeIn(duration: 0.4)) {
                    animationSpeed = 1.0
                }
            }
        }
    }

    // MARK: - Squiggle Path Builder

    /// Builds a single jagged squiggle path clustered around the center.
    private func buildSquiggle(
        index: Int,
        time: Double,
        speed: Double,
        center: CGPoint,
        size: CGSize
    ) -> Path {
        let phase = Double(index) * 1.37           // unique phase offset per thread
        let freqX = 0.8 + Double(index) * 0.15     // slightly different X frequency
        let freqY = 0.6 + Double(index) * 0.12     // slightly different Y frequency
        let spreadX = size.width * 0.18             // how far threads spread horizontally
        let spreadY = size.height * 0.14            // how far threads spread vertically

        var path = Path()

        for p in 0..<pointsPerThread {
            let t = Double(p) / Double(pointsPerThread) * .pi * 4

            // Primary wave
            let waveX = sin(t * freqX + time * speed * 0.7 + phase) * spreadX
            let waveY = cos(t * freqY + time * speed * 0.5 + phase * 0.8) * spreadY

            // Secondary jagged perturbation (higher frequency, smaller amplitude)
            let jagX = sin(t * 3.7 + time * speed * 1.3 + phase * 2.1) * spreadX * 0.25
            let jagY = cos(t * 4.3 + time * speed * 1.1 + phase * 1.7) * spreadY * 0.3

            // Tertiary micro-noise
            let noiseX = sin(t * 7.1 + time * speed * 0.9 + Double(index) * 3.3) * spreadX * 0.08
            let noiseY = cos(t * 6.3 + time * speed * 1.2 + Double(index) * 2.7) * spreadY * 0.08

            let x = center.x + waveX + jagX + noiseX
            let y = center.y + waveY + jagY + noiseY

            if p == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }

    // MARK: - Color Blending

    /// Linearly interpolates between two SwiftUI Colors via their resolved RGBA values.
    private func blendColor(from: Color, to: Color, t: Double) -> Color {
        let env = EnvironmentValues()
        let fromResolved = from.resolve(in: env)
        let toResolved = to.resolve(in: env)

        let r = Double(fromResolved.red) + (Double(toResolved.red) - Double(fromResolved.red)) * t
        let g = Double(fromResolved.green) + (Double(toResolved.green) - Double(fromResolved.green)) * t
        let b = Double(fromResolved.blue) + (Double(toResolved.blue) - Double(fromResolved.blue)) * t

        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    WovenThreadBackground(viewModel: FlowViewModel())
}
