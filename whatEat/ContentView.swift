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
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Welcome section
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.78, blue: 0.80),
                                    Color(red: 0.95, green: 0.60, blue: 0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome to My Kitchen!")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    if let name = authManager.userDisplayName {
                        Text("Hello, \(name)")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                    }
                }
                
                Spacer()
                
                // Placeholder content
                VStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                    
                    Text("Your recipes will appear here")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                
                Spacer()
                
                // Sign out button
                Button {
                    authManager.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.9, green: 0.4, blue: 0.4), lineWidth: 1.5)
                    )
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.99, blue: 0.98),
                        Color(red: 1.0, green: 0.98, blue: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
}
