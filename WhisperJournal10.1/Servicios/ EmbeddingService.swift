//
//   EmbeddingService.swift
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
    
    func generateEmbedding(for text: String, completion: @escaping ([Float]?, Error?) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "text-embedding-ada-002",
            "input": text
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(nil, error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay datos"]))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(EmbeddingResponse.self, from: data)
                if let embedding = response.data.first?.embedding {
                    DispatchQueue.main.async {
                        completion(embedding, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo generar el embedding"]))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error decodificando respuesta: \(error)")
                    if let str = String(data: data, encoding: .utf8) {
                        print("Respuesta raw: \(str)")
                    }
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // Función para calcular la similitud coseno entre dos embeddings
    func cosineSimilarity(between v1: [Float], and v2: [Float]) -> Float {
        guard v1.count == v2.count else { return 0 }
        
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let norm1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let norm2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        
        return dotProduct / (norm1 * norm2)
    }
}

// Estructuras para decodificar la respuesta de la API
struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
    let model: String
    let usage: Usage
    
    struct EmbeddingData: Codable {
        let embedding: [Float]
        let index: Int
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
