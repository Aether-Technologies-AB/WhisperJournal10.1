//
//  ConversationalSearchService.swift
//  WhisperJournal10.1
//
//  Created by andree on 17/03/25.
//

import Foundation
import FirebaseAuth

struct SearchResponse {
    let answer: String
    let usedTranscriptions: [Transcription]
}

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
    
    func performConversationalSearch(query: String, completion: @escaping (SearchResponse?, Error?) -> Void) {
        Task {
            do {
                // Generar embedding para la consulta
                let queryEmbedding = try await EmbeddingService.shared.generateEmbedding(for: query)
                
                guard let username = Auth.auth().currentUser?.email else {
                    completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("no_authenticated_user", comment: "")]))
                    return
                }
                
                // Primero buscar con Algolia
                AlgoliaService.shared.searchTranscriptions(query: query) { transcriptionIDs in
                    // Obtener todas las transcripciones
                    FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        
                        guard let transcriptions = transcriptions else {
                            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("no_transcriptions_found", comment: "")]))
                            return
                        }
                        
                        // Combinar resultados de Algolia y búsqueda semántica
                        var relevantTranscriptions = transcriptions.compactMap { transcription -> (Transcription, Float)? in
                            guard let embedding = transcription.embedding else { return nil }
                            let similarity = EmbeddingService.shared.calculateCosineSimilarity(between: queryEmbedding, and: embedding)
                            
                            // Si está en los resultados de Algolia, aumentar la similitud
                            if let id = transcription.id, transcriptionIDs.contains(id) {
                                return (transcription, max(similarity + 0.2, 1.0)) // Boost para resultados de Algolia
                            }
                            
                            return (transcription, similarity)
                        }
                        .filter { $0.1 > 0.5 } // Umbral de similitud más bajo para incluir más resultados
                        .sorted { $0.1 > $1.1 }
                        .map { $0.0 }
                        
                        // Si no hay resultados semánticos, usar solo los de Algolia
                        if relevantTranscriptions.isEmpty {
                            relevantTranscriptions = transcriptions.filter { transcription in
                                guard let id = transcription.id else { return false }
                                return transcriptionIDs.contains(id)
                            }
                        }
                        
                        guard !relevantTranscriptions.isEmpty else {
                            completion(SearchResponse(answer: NSLocalizedString("no_relevant_entries", comment: ""), usedTranscriptions: []), nil)
                            return
                        }
                        
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
                                let searchResponse = SearchResponse(
                                    answer: response,
                                    usedTranscriptions: relevantTranscriptions
                                )
                                completion(searchResponse, nil)
                            }
                        }
                    }
                }
            } catch {
                completion(nil, error)
            }
        }
    }
}
