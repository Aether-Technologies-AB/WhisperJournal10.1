//
//  OpenAIService.swift
//  WhisperJournal10.1
//
//  Created by andree on 17/03/25.
//

import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private init() {
        self.apiKey = APIKeys.openAI
    }
    
    func generateResponse(prompt: String, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        Eres un asistente que responde preguntas basándose en transcripciones de un diario personal.
        
        REGLAS ESTRICTAS:
        1. SOLO responde con la información específica solicitada
        2. NO agregues comentarios ni explicaciones adicionales
        3. NO uses frases como "según las transcripciones" o "en tu diario"
        4. Si no encuentras la información exacta, responde solo: "No encontré esa información"
        5. Da respuestas DIRECTAS y CONCISAS
        
        Ejemplos:
        Pregunta: "¿Cuándo fue mi cumpleaños?"
        Respuesta correcta: "El 5 de mayo"
        Respuesta incorrecta: "Según tus transcripciones, celebraste tu cumpleaños el 5 de mayo"
        
        Pregunta: "¿Qué hice el martes?"
        Respuesta correcta: "Fuiste al gimnasio y luego al cine"
        Respuesta incorrecta: "En tu diario mencionas que el martes realizaste actividades..."
        """
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": messages,
            "temperature": 0.3,  // Reducimos para respuestas más precisas
            "max_tokens": 150    // Reducimos para respuestas más cortas
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
                let response = try decoder.decode(OpenAIResponse.self, from: data)
                if let content = response.choices.first?.message.content {
                    DispatchQueue.main.async {
                        completion(content, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo generar una respuesta"]))
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
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}
