//
//  ExitView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI

struct ExitView: View {

    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("We got you.\nNow go back to sleep.")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.35))
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                textOpacity = 1
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
