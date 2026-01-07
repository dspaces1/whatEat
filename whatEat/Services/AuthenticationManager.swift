//
//  AuthenticationManager.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Observation

/// Manages Sign in with Apple authentication flow following Apple's best practices.
@Observable
@MainActor
final class AuthenticationManager: NSObject {
    
    // MARK: - Published Properties
    
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    
    /// The current user's display name (if available)
    var userDisplayName: String?
    
    /// The current user's email (if available)
    var userEmail: String?
    
    // MARK: - Private Properties
    
    private let keychain = KeychainService.shared
    private var currentWindow: UIWindow?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        // Check authentication state on initialization
        Task {
            await checkExistingCredentials()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initiates the Sign in with Apple flow
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        // Cache the current window before starting
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            currentWindow = scene.windows.first
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    /// Signs out the current user and clears stored credentials
    func signOut() {
        // Get access token before clearing (for backend call)
        let accessToken = keychain.getAccessToken()
        
        // Clear local state immediately
        keychain.clearAllCredentials()
        isAuthenticated = false
        userDisplayName = nil
        userEmail = nil
        
        // Best-effort backend sign out (don't block on this)
        if let token = accessToken {
            Task {
                await signOutFromBackend(accessToken: token)
            }
        }
    }
    
    /// Notifies backend of sign out (best-effort, continues even if it fails)
    private func signOutFromBackend(accessToken: String) async {
        do {
            let _: SignOutResponse = try await APIService.shared.postAuthenticated(
                path: "/auth/signout",
                accessToken: accessToken
            )
            print("[Auth] ✅ Backend sign out successful")
        } catch {
            // Sign out is best-effort - we already cleared local state
            print("[Auth] ⚠️ Backend sign out failed (continuing anyway): \(error)")
        }
    }
    
    /// Checks if the user has existing valid credentials
    func checkExistingCredentials() async {
        guard let userIdentifier = keychain.getUserIdentifier() else {
            isAuthenticated = false
            return
        }
        
        // Verify the credential state with Apple
        let provider = ASAuthorizationAppleIDProvider()
        
        do {
            let credentialState = try await provider.credentialState(forUserID: userIdentifier)
            
            switch credentialState {
            case .authorized:
                // Apple credential is valid, now check backend tokens
                if keychain.getRefreshToken() != nil {
                    // We have backend tokens - try to ensure they're valid
                    do {
                        _ = try await getValidAccessToken()
                        isAuthenticated = true
                        userDisplayName = keychain.getUserFullName()
                        userEmail = keychain.getUserEmail()
                    } catch {
                        // Backend tokens invalid - need to re-authenticate
                        print("[Auth] Backend tokens invalid: \(error)")
                        keychain.clearAllCredentials()
                        isAuthenticated = false
                    }
                } else {
                    // No backend tokens - need to re-authenticate
                    print("[Auth] No backend tokens found")
                    keychain.clearAllCredentials()
                    isAuthenticated = false
                }
                
            case .revoked, .notFound:
                // Credentials are no longer valid
                keychain.clearAllCredentials()
                isAuthenticated = false
                
            case .transferred:
                // Handle account transfer (rare case for enterprise)
                keychain.clearAllCredentials()
                isAuthenticated = false
                
            @unknown default:
                isAuthenticated = false
            }
        } catch {
            // If we can't verify, treat as not authenticated
            print("[Auth] Error checking credential state: \(error)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Token Management
    
    /// Returns a valid access token, refreshing if needed.
    /// Use this for making authenticated API requests.
    /// - Returns: A valid access token
    /// - Throws: AuthError if unable to get a valid token
    func getValidAccessToken() async throws -> String {
        // Check if current token is valid (with 5 minute buffer)
        if let accessToken = keychain.getAccessToken(),
           let expiresAt = keychain.getExpiresAt() {
            let expirationDate = Date(timeIntervalSince1970: TimeInterval(expiresAt))
            let bufferDate = Date().addingTimeInterval(300) // 5 minutes buffer
            
            if expirationDate > bufferDate {
                // Token is still valid
                return accessToken
            }
        }
        
        // Token expired or about to expire - refresh it
        guard let refreshToken = keychain.getRefreshToken() else {
            throw AuthError.notLoggedIn
        }
        
        return try await refreshTokens(refreshToken)
    }
    
    /// Refreshes the access token using the refresh token
    private func refreshTokens(_ refreshToken: String) async throws -> String {
        let request = RefreshRequest(refreshToken: refreshToken)
        
        do {
            let response: AuthResponse = try await APIService.shared.post(
                path: "/auth/refresh",
                body: request
            )
            
            // Save the new tokens (both are rotated on refresh)
            keychain.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresAt: response.expiresAt
            )
            
            print("[Auth] ✅ Tokens refreshed successfully")
            return response.accessToken
            
        } catch let error as APIError {
            if case .unauthorized = error {
                // Refresh token expired - user must sign in again
                print("[Auth] ❌ Refresh token expired - session ended")
                await MainActor.run {
                    keychain.clearAllCredentials()
                    isAuthenticated = false
                }
                throw AuthError.sessionExpired
            }
            throw error
        }
    }
    
    // MARK: - Private Authorization Handlers
    
    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            isLoading = false
            errorMessage = "Invalid credential type received"
            return
        }
        
        // Extract the identity token (JWT) - required for backend auth
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            isLoading = false
            errorMessage = AuthError.missingIdentityToken.localizedDescription
            return
        }
        
        // Store the user identifier locally (always provided)
        let userIdentifier = credential.user
        keychain.saveUserIdentifier(userIdentifier)
        
        // Capture full name if provided (only on first sign-in)
        var fullNameForRequest: SignInRequest.FullName?
        if let fullName = credential.fullName {
            let formattedName = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default)
            if !formattedName.isEmpty {
                keychain.saveUserFullName(formattedName)
                userDisplayName = formattedName
            }
            // Send the components to backend
            if fullName.givenName != nil || fullName.familyName != nil {
                fullNameForRequest = SignInRequest.FullName(
                    givenName: fullName.givenName,
                    familyName: fullName.familyName
                )
            }
        }
        
        // Store email locally if provided (only on first sign-in)
        if let email = credential.email {
            keychain.saveUserEmail(email)
            userEmail = email
        }
        
        // Load any previously stored values
        if userDisplayName == nil {
            userDisplayName = keychain.getUserFullName()
        }
        if userEmail == nil {
            userEmail = keychain.getUserEmail()
        }
        
        // Call backend to exchange identity token for session tokens
        Task {
            await signInWithBackend(idToken: identityToken, fullName: fullNameForRequest)
        }
    }
    
    /// Exchanges Apple identity token for backend session tokens
    private func signInWithBackend(idToken: String, fullName: SignInRequest.FullName?) async {
        let request = SignInRequest(
            provider: "apple",
            idToken: idToken,
            fullName: fullName
        )
        
        do {
            let response: AuthResponse = try await APIService.shared.post(
                path: "/auth/signin",
                body: request
            )
            
            // Store backend tokens
            keychain.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                expiresAt: response.expiresAt
            )
            
            print("[Auth] ✅ Signed in as user: \(response.user.id)")
            isAuthenticated = true
            isLoading = false
            
        } catch let error as APIError {
            print("[Auth] ❌ Backend auth failed: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
            // Clear local credentials since backend auth failed
            keychain.clearAllCredentials()
            
        } catch {
            print("[Auth] ❌ Backend auth failed: \(error)")
            isLoading = false
            errorMessage = "Sign in failed. Please try again."
            keychain.clearAllCredentials()
        }
    }
    
    private func handleAuthorizationError(_ error: Error) {
        isLoading = false
        
        // Log the full error for debugging
        print("[Auth] Authorization error: \(error)")
        print("[Auth] Error localized description: \(error.localizedDescription)")
        
        if let authError = error as? ASAuthorizationError {
            print("[Auth] ASAuthorizationError code: \(authError.code.rawValue)")
            print("[Auth] ASAuthorizationError underlying: \(String(describing: authError.userInfo))")
            
            let errorCode = authError.code
            if errorCode == .canceled {
                // User canceled - don't show error
                return
            } else if errorCode == .failed {
                errorMessage = "Authorization failed. Please try again."
            } else if errorCode == .invalidResponse {
                errorMessage = "Invalid response from Apple. Please try again."
            } else if errorCode == .notHandled {
                errorMessage = "Authorization request not handled."
            } else if errorCode == .notInteractive {
                errorMessage = "Authorization requires user interaction."
            } else if errorCode == .unknown {
                // This often happens on simulator when not signed into Apple ID
                // or when entitlements are not properly configured
                errorMessage = "Sign in with Apple is not available. On simulator, please sign into an Apple ID in Settings > Apple Account."
            } else if errorCode == .matchedExcludedCredential {
                errorMessage = "This credential has been excluded."
            } else {
                errorMessage = "An error occurred. Please try again."
            }
        } else {
            // Log any other error type
            print("[Auth] Non-ASAuthorizationError: \(type(of: error))")
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            handleAuthorization(authorization)
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            handleAuthorizationError(error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // This must return synchronously, so we use DispatchQueue.main.sync if needed
        // But we cached the window on the main thread before starting
        DispatchQueue.main.sync {
            if let window = self.currentWindow {
                return window
            }
            
            // Fallback: try to get window now
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                return window
            }
            
            // Last resort: create a new window
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return UIWindow(windowScene: scene)
            }
            
            // This shouldn't happen, but provide a fallback
            return UIWindow()
        }
    }
}
