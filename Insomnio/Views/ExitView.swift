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

    var body: some View {
        ZStack {
            WovenThreadBackground(viewModel: viewModel)

            Text("We got you.\nNow go back to sleep.")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(Color("Peach"))
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

#Preview {
    ExitView(viewModel: FlowViewModel())
}
