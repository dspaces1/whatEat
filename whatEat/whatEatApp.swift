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
                if authManager.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environment(authManager)
        }
    }
}
