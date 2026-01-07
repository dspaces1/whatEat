//
//  APIService.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/6/26.
//

import Foundation

/// Centralized API service for making network requests to the whatEat backend.
actor APIService {
    
    static let shared = APIService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://whateatbe.onrender.com/api/v1"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Performs a POST request with JSON body and returns decoded response.
    /// - Parameters:
    ///   - path: API endpoint path (e.g., "/auth/signin")
    ///   - body: Encodable request body
    /// - Returns: Decoded response of type T
    func post<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    /// Performs a POST request with authorization header.
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - body: Encodable request body
    ///   - accessToken: Bearer token for authorization
    /// - Returns: Decoded response of type T
    func postAuthenticated<T: Decodable, U: Encodable>(
        path: String,
        body: U,
        accessToken: String
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    /// Performs an authenticated POST request with empty body.
    /// - Parameters:
    ///   - path: API endpoint path
    ///   - accessToken: Bearer token for authorization
    /// - Returns: Decoded response of type T
    func postAuthenticated<T: Decodable>(
        path: String,
        accessToken: String
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = "{}".data(using: .utf8)
        
        return try await performRequest(request)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log for debugging
        print("[API] \(request.httpMethod ?? "?") \(request.url?.path ?? "?") -> \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("[API] Decode error: \(error)")
                throw APIError.decodingError(error)
            }
            
        case 400:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.error ?? "Bad request")
            
        case 401:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.unauthorized(errorResponse?.error ?? "Unauthorized")
            
        case 500...599:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.error ?? "Server error")
            
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - API Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case badRequest(String)
    case unauthorized(String)
    case serverError(String)
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .badRequest(let message):
            return message
        case .unauthorized(let message):
            return message
        case .serverError(let message):
            return message
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}

/// Response structure for API errors
struct APIErrorResponse: Decodable, Sendable {
    let error: String
    let code: String?
}

