//
//  ContentView.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        HomeView()
            .environment(authManager)
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
}
