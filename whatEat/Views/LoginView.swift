//
//  LoginView.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 40)
                    
                    // App icon and title
                    headerSection
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // Mascot illustration area
                    mascotSection
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Headline and description
                    textSection
                    
                    Spacer()
                    
                    // Sign in button and terms
                    bottomSection
                    
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom + 20)
                }
                .padding(.horizontal, 24)
            }
            .ignoresSafeArea()
        }
        .alert("Sign In Error", isPresented: .init(
            get: { authManager.errorMessage != nil },
            set: { if !$0 { authManager.errorMessage = nil } }
        )) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.98, blue: 0.94), // Light cream-green
                Color(red: 1.0, green: 0.96, blue: 0.91),  // Soft peach
                Color(red: 1.0, green: 0.93, blue: 0.87)   // Warm peach
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // App icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.78, blue: 0.80)) // Soft pink
                    .frame(width: 64, height: 64)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Title
            Text("My Kitchen")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
        }
    }
    
    // MARK: - Mascot Section
    
    private var mascotSection: some View {
        ZStack {
            // White blob background
            BlobShape()
                .fill(.white)
                .frame(width: 320, height: 320)
                .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 10)
            
            // Mascot placeholder (cat chef)
            VStack(spacing: 8) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 100))
                    .foregroundColor(Color(red: 0.95, green: 0.70, blue: 0.50))
                
                // Chef hat
                Image(systemName: "cloud.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .overlay(
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
                            .offset(y: 2)
                    )
                    .offset(y: -140)
            }
            
            // "Yummy!" bubble
            HStack(spacing: 4) {
                Text("🍰")
                    .font(.system(size: 14))
                Text("Yummy!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .offset(x: 100, y: -80)
            
            // Floating salad icon
            Text("🥗")
                .font(.system(size: 32))
                .padding(8)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
                .offset(x: -130, y: 60)
        }
    }
    
    // MARK: - Text Section
    
    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Cooking Made Fun")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
            
            Text("Collect your favorite kawaii recipes and start\nyour cooking adventure today!")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // Custom Sign in with Apple button using our AuthenticationManager
            Button {
                authManager.signInWithApple()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                    Text("Continue with Apple")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .disabled(authManager.isLoading)
            .overlay(
                Group {
                    if authManager.isLoading {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.black.opacity(0.3))
                        ProgressView()
                            .tint(.white)
                    }
                }
            )
            
            // Terms text
            Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Blob Shape

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = rect.midX
        let centerY = rect.midY
        
        // Create an organic blob shape
        path.move(to: CGPoint(x: centerX, y: 0))
        
        // Top right curve
        path.addCurve(
            to: CGPoint(x: width, y: centerY),
            control1: CGPoint(x: width * 0.7, y: 0),
            control2: CGPoint(x: width, y: height * 0.3)
        )
        
        // Bottom right curve
        path.addCurve(
            to: CGPoint(x: centerX, y: height),
            control1: CGPoint(x: width, y: height * 0.7),
            control2: CGPoint(x: width * 0.7, y: height)
        )
        
        // Bottom left curve
        path.addCurve(
            to: CGPoint(x: 0, y: centerY),
            control1: CGPoint(x: width * 0.3, y: height),
            control2: CGPoint(x: 0, y: height * 0.7)
        )
        
        // Top left curve (back to start)
        path.addCurve(
            to: CGPoint(x: centerX, y: 0),
            control1: CGPoint(x: 0, y: height * 0.3),
            control2: CGPoint(x: width * 0.3, y: 0)
        )
        
        return path
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AuthenticationManager())
}
