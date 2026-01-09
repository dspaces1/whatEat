//
//  whatEatApp.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import SwiftUI

@main
struct whatEatApp: App {
    @State private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .checking:
                    SplashStateView()
                case .authenticated:
                    ContentView()
                case .signedOut:
                    LoginView()
                }
            }
            .animation(.easeInOut, value: authManager.authState)
            .environment(authManager)
        }
    }
}

private struct SplashStateView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ProgressView("Checking your session…")
                .progressViewStyle(.circular)
        }
    }
}
