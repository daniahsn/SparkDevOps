//
//  APIClient.swift
//  Spark
//
//  API Client for connecting to backend
//

import Foundation
import Combine

class APIClient {
    static let shared = APIClient()
    
    // Change this to your backend URL
    // For iOS Simulator: http://localhost:5001
    // For physical device: http://<your-mac-ip>:5001 (find IP with: ifconfig | grep 'inet ')
    // For production: your deployed backend URL
    private let baseURL = "http://localhost:5001"
    
    private init() {}
    
    // MARK: - Health Check
    
    func checkHealth() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        return true
    }
    
    // MARK: - CRUD Operations
    
    func fetchEntries() async throws -> [SparkEntry] {
        guard let url = URL(string: "\(baseURL)/api/entries") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error \(httpResponse.statusCode): \(errorString)")
            }
            throw APIError.serverError
        }
        
        // Check if response is empty
        guard !data.isEmpty else {
            print("❌ Empty response from API")
            throw APIError.decodingError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let entries = try decoder.decode([SparkEntry].self, from: data)
            return entries
        } catch {
            // Log the actual decoding error and response
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Decoding error. Response: \(responseString.prefix(500))")
            }
            print("❌ Decoding error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            throw APIError.decodingError
        }
    }
    
    func fetchEntry(id: UUID) async throws -> SparkEntry {
        guard let url = URL(string: "\(baseURL)/api/entries/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(SparkEntry.self, from: data)
        return entry
    }
    
    func createEntry(_ entry: SparkEntry) async throws -> SparkEntry {
        guard let url = URL(string: "\(baseURL)/api/entries") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(entry)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let createdEntry = try decoder.decode(SparkEntry.self, from: data)
        return createdEntry
    }
    
    func updateEntry(_ entry: SparkEntry) async throws -> SparkEntry {
        guard let url = URL(string: "\(baseURL)/api/entries/\(entry.id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(entry)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }
        
        guard httpResponse.statusCode == 200 else {
            // Log the error response for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ API Error \(httpResponse.statusCode): \(errorString)")
            }
            if httpResponse.statusCode == 404 {
                throw APIError.decodingError  // Entry not found
            }
            throw APIError.serverError
        }
        
        // Check if response is empty
        guard !data.isEmpty else {
            print("❌ Empty response from API")
            throw APIError.decodingError
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let updatedEntry = try decoder.decode(SparkEntry.self, from: data)
            return updatedEntry
        } catch {
            // Log the actual decoding error and response
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Decoding error. Response: \(responseString)")
            }
            print("❌ Decoding error: \(error.localizedDescription)")
            throw APIError.decodingError
        }
    }
    
    func deleteEntry(id: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/api/entries/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func unlockEntry(id: UUID) async throws -> SparkEntry {
        guard let url = URL(string: "\(baseURL)/api/entries/\(id.uuidString)/unlock") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entry = try decoder.decode(SparkEntry.self, from: data)
        return entry
    }
}

enum APIError: Error {
    case invalidURL
    case serverError
    case decodingError
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error"
        }
    }
}

