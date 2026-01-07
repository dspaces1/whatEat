//
//  AuthModels.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/6/26.
//

import Foundation

// MARK: - Request Models

/// Request body for POST /auth/signin
struct SignInRequest: Encodable {
    let provider: String
    let idToken: String
    let fullName: FullName?
    
    struct FullName: Encodable {
        let givenName: String?
        let familyName: String?
    }
}

/// Request body for POST /auth/refresh
struct RefreshRequest: Encodable {
    let refreshToken: String
}

// MARK: - Response Models

/// Response from POST /auth/signin and POST /auth/refresh
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let expiresAt: Int
    let user: AuthUser
}

/// User information returned from auth endpoints
struct AuthUser: Decodable {
    let id: String
    let email: String?
    let createdAt: String
}

/// Response from POST /auth/signout
struct SignOutResponse: Decodable {
    let success: Bool
}

// MARK: - Auth Error Types

enum AuthError: LocalizedError {
    case notLoggedIn
    case sessionExpired
    case missingIdentityToken
    case backendAuthFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "You are not logged in"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .missingIdentityToken:
            return "Failed to get identity token from Apple"
        case .backendAuthFailed(let message):
            return message
        }
    }
}

