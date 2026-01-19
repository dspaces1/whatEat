//
//  APIService.swift
//  whatEat
//
//  Created by Diego Urquiza on 1/6/26.
//

import Foundation
import Pulse

/// Centralized API service for making network requests to the whatEat backend.
actor APIService {
    
    static let shared = APIService()
    
    // MARK: - Configuration
    
    private let baseURL = "https://whateatbe.onrender.com/api/v1"
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()
    
    private let session: URLSessionProtocol

    private init() {
        session = NetworkSessionFactory.makeSession()
    }
    
    // MARK: - Public Methods
    
    /// Performs a POST request with JSON body and returns decoded response.
    /// - Parameters:
    ///   - path: API endpoint path (e.g., "/auth/signin")
    ///   - body: Encodable request body
    /// - Returns: Decoded response of type T
    func post<T: Decodable, U: Encodable>(path: String, body: U) async throws -> T {
        guard let url = makeURL(path: path) else {
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
        guard let url = makeURL(path: path) else {
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
        guard let url = makeURL(path: path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = "{}".data(using: .utf8)
        
        return try await performRequest(request)
    }

    /// Performs an authenticated PATCH request with JSON body.
    func patchAuthenticated<T: Decodable, U: Encodable>(
        path: String,
        body: U,
        accessToken: String
    ) async throws -> T {
        guard let url = makeURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)

        return try await performRequest(request)
    }

    /// Performs a GET request and returns decoded response.
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard let url = makeURL(path: path, queryItems: queryItems) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return try await performRequest(request)
    }

    /// Performs a GET request with authorization header.
    func getAuthenticated<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        accessToken: String
    ) async throws -> T {
        guard let url = makeURL(path: path, queryItems: queryItems) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await performRequest(request)
    }

    /// Performs a DELETE request with authorization header.
    func deleteAuthenticated(
        path: String,
        accessToken: String
    ) async throws {
        guard let url = makeURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        try await performVoidRequest(request)
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log for debugging
        print("[API] \(request.httpMethod ?? "?") \(request.url?.path ?? "?") -> \(httpResponse.statusCode)")

        if (400...599).contains(httpResponse.statusCode) {
            logNetworkFailure(request: request, response: httpResponse, data: data)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("[API] Decode error: \(error)")
                logNetworkFailure(request: request, response: httpResponse, data: data)
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

    private func performVoidRequest(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        print("[API] \(request.httpMethod ?? "?") \(request.url?.path ?? "?") -> \(httpResponse.statusCode)")

        if (400...599).contains(httpResponse.statusCode) {
            logNetworkFailure(request: request, response: httpResponse, data: data)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
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

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(path)")
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    private func logNetworkFailure(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data
    ) {
        var lines: [String] = []
        lines.append("[API] Request")
        lines.append("  Method: \(request.httpMethod ?? "N/A")")
        lines.append("  URL: \(request.url?.absoluteString ?? "N/A")")
        lines.append("  Headers: \(formatHeaders(request.allHTTPHeaderFields))")
        lines.append("  Body: \(formatBody(request.httpBody))")
        lines.append("[API] Response")
        lines.append("  Status: \(response.statusCode)")
        lines.append("  Headers: \(formatHeaders(response.allHeaderFields))")
        lines.append("  Body: \(formatBody(data))")
        print(lines.joined(separator: "\n"))
    }

    private func formatHeaders(_ headers: [AnyHashable: Any]?) -> String {
        guard let headers, !headers.isEmpty else {
            return "{}"
        }
        let pairs = headers
            .sorted { String(describing: $0.key) < String(describing: $1.key) }
            .map { key, value in
                "\(key): \(value)"
            }
        return "{ " + pairs.joined(separator: ", ") + " }"
    }

    private func formatHeaders(_ headers: [String: String]?) -> String {
        guard let headers, !headers.isEmpty else {
            return "{}"
        }
        let pairs = headers
            .sorted { $0.key < $1.key }
            .map { key, value in
                "\(key): \(value)"
            }
        return "{ " + pairs.joined(separator: ", ") + " }"
    }

    private func formatBody(_ body: Data?) -> String {
        guard let body, !body.isEmpty else {
            return "<empty>"
        }

        if let object = try? JSONSerialization.jsonObject(with: body, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString.replacingOccurrences(of: "\n", with: " ")
        }

        if let string = String(data: body, encoding: .utf8) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "<empty>" : trimmed
        }

        return "<\(body.count) bytes>"
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
