//
//  ContentView.swift
//  Insomnio
//
//  Created by Gabriel Tanod on 23/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var viewModel = FlowViewModel()

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            IntroView(viewModel: viewModel)
                .navigationDestination(for: FlowStep.self) { step in
                    switch step {
                    case .intro:
                        IntroView(viewModel: viewModel)
                    case .record:
                        RecordView(viewModel: viewModel)
                    case .review:
                        ReviewView(viewModel: viewModel)
                    case .exit:
                        ExitView()
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DailyLog.self, inMemory: true)
}
