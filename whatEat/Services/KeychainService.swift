//
//  KeychainService.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/4/26.
//

import Foundation
import Security

/// A service for securely storing and retrieving user credentials in the Keychain.
/// Used primarily for storing the Apple Sign In user identifier.
final class KeychainService {
    
    static let shared = KeychainService()
    
    private let service = "com.whatEat.auth"
    private let userIdentifierKey = "appleUserIdentifier"
    private let userEmailKey = "appleUserEmail"
    private let userFullNameKey = "appleUserFullName"
    
    // Backend token keys
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let expiresAtKey = "expiresAt"
    
    private init() {}
    
    // MARK: - User Identifier
    
    /// Saves the Apple user identifier to Keychain
    /// - Parameter userIdentifier: The unique identifier provided by Apple Sign In
    /// - Returns: True if save was successful
    @discardableResult
    func saveUserIdentifier(_ userIdentifier: String) -> Bool {
        guard let data = userIdentifier.data(using: .utf8) else { return false }
        return save(data: data, forKey: userIdentifierKey)
    }
    
    /// Retrieves the stored Apple user identifier from Keychain
    /// - Returns: The user identifier if found, nil otherwise
    func getUserIdentifier() -> String? {
        guard let data = retrieve(forKey: userIdentifierKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - User Email (Optional - only provided on first sign-in)
    
    /// Saves the user's email to Keychain
    /// - Parameter email: The email provided by Apple Sign In
    /// - Returns: True if save was successful
    @discardableResult
    func saveUserEmail(_ email: String) -> Bool {
        guard let data = email.data(using: .utf8) else { return false }
        return save(data: data, forKey: userEmailKey)
    }
    
    /// Retrieves the stored user email from Keychain
    /// - Returns: The email if found, nil otherwise
    func getUserEmail() -> String? {
        guard let data = retrieve(forKey: userEmailKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - User Full Name (Optional - only provided on first sign-in)
    
    /// Saves the user's full name to Keychain
    /// - Parameter fullName: The full name provided by Apple Sign In
    /// - Returns: True if save was successful
    @discardableResult
    func saveUserFullName(_ fullName: String) -> Bool {
        guard let data = fullName.data(using: .utf8) else { return false }
        return save(data: data, forKey: userFullNameKey)
    }
    
    /// Retrieves the stored user full name from Keychain
    /// - Returns: The full name if found, nil otherwise
    func getUserFullName() -> String? {
        guard let data = retrieve(forKey: userFullNameKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Backend Tokens
    
    /// Saves the access token to Keychain
    /// - Parameter token: The JWT access token from the backend
    /// - Returns: True if save was successful
    @discardableResult
    func saveAccessToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return save(data: data, forKey: accessTokenKey)
    }
    
    /// Retrieves the stored access token from Keychain
    /// - Returns: The access token if found, nil otherwise
    func getAccessToken() -> String? {
        guard let data = retrieve(forKey: accessTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Saves the refresh token to Keychain
    /// - Parameter token: The refresh token from the backend
    /// - Returns: True if save was successful
    @discardableResult
    func saveRefreshToken(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        return save(data: data, forKey: refreshTokenKey)
    }
    
    /// Retrieves the stored refresh token from Keychain
    /// - Returns: The refresh token if found, nil otherwise
    func getRefreshToken() -> String? {
        guard let data = retrieve(forKey: refreshTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Saves the token expiration timestamp to Keychain
    /// - Parameter timestamp: Unix timestamp when the access token expires
    /// - Returns: True if save was successful
    @discardableResult
    func saveExpiresAt(_ timestamp: Int) -> Bool {
        guard let data = String(timestamp).data(using: .utf8) else { return false }
        return save(data: data, forKey: expiresAtKey)
    }
    
    /// Retrieves the stored expiration timestamp from Keychain
    /// - Returns: The expiration timestamp if found, nil otherwise
    func getExpiresAt() -> Int? {
        guard let data = retrieve(forKey: expiresAtKey),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return Int(string)
    }
    
    /// Saves all backend tokens at once
    /// - Parameters:
    ///   - accessToken: The JWT access token
    ///   - refreshToken: The refresh token
    ///   - expiresAt: Unix timestamp when access token expires
    func saveTokens(accessToken: String, refreshToken: String, expiresAt: Int) {
        saveAccessToken(accessToken)
        saveRefreshToken(refreshToken)
        saveExpiresAt(expiresAt)
    }
    
    /// Clears all backend tokens from Keychain
    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
        delete(forKey: expiresAtKey)
    }
    
    // MARK: - Clear All
    
    /// Removes all stored credentials from Keychain (for sign out)
    func clearAllCredentials() {
        // Clear Apple credentials
        delete(forKey: userIdentifierKey)
        delete(forKey: userEmailKey)
        delete(forKey: userFullNameKey)
        // Clear backend tokens
        clearTokens()
    }
    
    // MARK: - Private Keychain Operations
    
    private func save(data: Data, forKey key: String) -> Bool {
        // First, try to delete any existing item
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func retrieve(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    @discardableResult
    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}




