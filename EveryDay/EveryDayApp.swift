//
//  EveryDayApp.swift
//  EveryDay
//
//  Created by Chris Melamed on 2/21/24.
//

import SwiftUI

@main
struct EveryDayApp: App {
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some Scene {
        WindowGroup {
            if viewModel.useFaceID {
                if viewModel.isUnlocked {
                    ContentView()
                        .environmentObject(viewModel)
                        .preferredColorScheme(getPreferredColorScheme())
                } else {
                    LoadingView()
                        .onAppear {
                            viewModel.authenticateUser()
                        }
                }
            } else {
                ContentView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(getPreferredColorScheme())
            }
        }
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        switch viewModel.appearanceOption {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}
