//
//  EmbeddingService.swift
//  WhisperJournal10.1
//
//  Created by andree on 22/03/25.
//

import Foundation
import Foundation

class EmbeddingService {
    static let shared = EmbeddingService()
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/embeddings"
    
    private init() {
        self.apiKey = APIKeys.openAI
    }
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "text-embedding-ada-002",
            "input": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        
        return response.data.first?.embedding ?? []
    }
    
    func calculateCosineSimilarity(between v1: [Float], and v2: [Float]) -> Float {
        guard v1.count == v2.count && !v1.isEmpty else { return 0 }
        
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let norm1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let norm2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (norm1 * norm2)
    }
}

struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
    
    struct EmbeddingData: Codable {
        let embedding: [Float]
    }
}
