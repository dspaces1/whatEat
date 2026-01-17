//
//  whatEatApp.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import SwiftUI

@main
struct whatEatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authManager = AuthenticationManager()
    @State private var savedRecipesStore = SavedRecipesStore()
    @State private var showDebugMenu = false
    
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
            .environment(savedRecipesStore)
            .onChange(of: authManager.authState) { _, newState in
                if newState == .signedOut {
                    savedRecipesStore.reset()
                }
            }
#if DEBUG
            .background(ShakeDetectorView {
                showDebugMenu = true
            })
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
            }
#endif
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
