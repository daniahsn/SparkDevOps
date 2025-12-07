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
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([SparkEntry].self, from: data)
        return entries
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let updatedEntry = try decoder.decode(SparkEntry.self, from: data)
        return updatedEntry
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

