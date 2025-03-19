//
//  ConversationalSearchService.swift
//  WhisperJournal10.1
//
//  Created by andree on 17/03/25.
//

import Foundation
import FirebaseAuth

class ConversationalSearchService {
    static let shared = ConversationalSearchService()
    
    func extractKeywords(from query: String, completion: @escaping (String?, Error?) -> Void) {
        let keywordPrompt = """
        TAREA: Extrae SOLO las palabras clave más importantes de la pregunta.
        NO respondas la pregunta, SOLO extrae las palabras clave.
        
        REGLAS:
        1. Devuelve SOLO las palabras clave separadas por espacios
        2. NO uses puntuación ni otros caracteres
        3. Usa palabras en singular
        4. Ignora palabras comunes como "el", "la", "mi", "fue", etc.
        
        Ejemplos:
        Pregunta: "¿Cuándo fue mi cumpleaños?"
        Palabras clave: cumpleaños
        
        Pregunta: "¿Qué hice el martes pasado?"
        Palabras clave: martes hacer
        
        Pregunta: "¿Dónde dejé mis llaves ayer?"
        Palabras clave: llaves ayer dejar
        
        PREGUNTA: \(query)
        PALABRAS CLAVE:
        """
        
        OpenAIService.shared.generateResponse(prompt: keywordPrompt) { keywords, error in
            completion(keywords, error)
        }
    }
    
    func performConversationalSearch(query: String, completion: @escaping (String?, Error?) -> Void) {
        // Primero extraemos las palabras clave de la pregunta
        extractKeywords(from: query) { keywords, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let keywords = keywords?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudieron extraer palabras clave"]))
                return
            }
            
            print("🔑 Palabras clave extraídas: \(keywords)")
            
            // Luego buscamos con las palabras clave
            AlgoliaService.shared.searchTranscriptions(query: keywords) { transcriptionIDs in
                guard let username = Auth.auth().currentUser?.email else {
                    completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"]))
                    return
                }
                
                FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    
                    guard let transcriptions = transcriptions else {
                        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se encontraron transcripciones"]))
                        return
                    }
                    
                    let relevantTranscriptions = transcriptions.filter { transcription in
                        guard let id = transcription.id else { return false }
                        return transcriptionIDs.contains(id)
                    }.sorted(by: { $0.date > $1.date })
                    
                    guard !relevantTranscriptions.isEmpty else {
                        completion("No encontré esa información en las transcripciones", nil)
                        return
                    }
                    
                    // Preparar el contexto para GPT
                    var context = "INFORMACIÓN DEL DIARIO:\n\n"
                    
                    for transcription in relevantTranscriptions {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .long
                        dateFormatter.timeStyle = .short
                        dateFormatter.locale = Locale(identifier: "es_ES")
                        
                        context += "[\(dateFormatter.string(from: transcription.date))]\n"
                        context += "\(transcription.text)\n\n"
                    }
                    
                    context += "\nPREGUNTA DEL USUARIO: \(query)\n"
                    context += "INSTRUCCIÓN: Responde SOLO con la información específica solicitada. No agregues explicaciones ni frases adicionales."
                    
                    OpenAIService.shared.generateResponse(prompt: context) { response, error in
                        if let error = error {
                            completion(nil, error)
                        } else if let response = response {
                            completion(response, nil)
                        }
                    }
                }
            }
        }
    }
}
