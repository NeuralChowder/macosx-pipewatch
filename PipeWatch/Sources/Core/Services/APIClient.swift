import Foundation

/// Generic API client for making HTTP requests
class APIClient {
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    // MARK: - GET Request
    
    func get<T: Decodable>(
        _ path: String,
        queryItems: [String: String]? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - POST Request
    
    func post(
        _ path: String,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws {
        let url = try buildURL(path: path, queryItems: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }
    
    func post<T: Decodable>(
        _ path: String,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Helpers
    
    private func buildURL(path: String, queryItems: [String: String]?) throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems {
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        return url
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            throw APIError.validationError(parseErrorMessage(data))
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknown(httpResponse.statusCode, parseErrorMessage(data))
        }
    }
    
    private func parseErrorMessage(_ data: Data) -> String {
        if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            return errorResponse.message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError(String)
    case rateLimited
    case serverError(Int)
    case unknown(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Invalid or expired token. Please re-authenticate."
        case .forbidden:
            return "Access denied. Please check your token permissions."
        case .notFound:
            return "Resource not found"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .unknown(let code, let message):
            return "Error (\(code)): \(message)"
        }
    }
}

struct ErrorResponse: Codable {
    let message: String
}
