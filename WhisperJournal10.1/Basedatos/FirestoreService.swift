//
//  FirestoreService.swift
//  WhisperJournal10.1
//
//  Created by andree on 4/01/25.
//
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import UIKit

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // Función para generar embeddings
    func generateEmbedding(from text: String, completion: @escaping ([Float]?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/embeddings") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "input": text,
            "model": "text-embedding-ada-002"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching embedding: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                // Parsear la respuesta JSON
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]],
                   let embeddingArray = dataArray.first?["embedding"] as? [Float] {
                    // Devolver el embedding como un array de flotantes
                    completion(embeddingArray)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // Método para buscar transcripciones usando embeddings
    func searchTranscriptions(username: String, query: String, completion: @escaping ([Transcription]?, Error?) -> Void) {
        generateEmbedding(from: query) { queryEmbedding in
            self.db.collection("users").document(username).collection("transcriptions").getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                } else {
                    let transcriptions = snapshot?.documents.compactMap { document -> Transcription? in
                        let data = document.data()
                        // Aquí deberías comparar el embedding de la consulta con los embeddings almacenados
                        // Si hay coincidencia, devuelve la transcripción
                        return try? document.data(as: Transcription.self)
                    }
                    completion(transcriptions, nil)
                }
            }
        }
    }
    
    func saveUser(username: String, password: String, completion: @escaping (Error?) -> Void) {
        let user = ["username": username, "password": password]
        db.collection("users").document(username).setData(user) { error in
            completion(error)
        }
    }
    
    func fetchUser(username: String, completion: @escaping (String?, Error?) -> Void) {
        db.collection("users").document(username).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let password = data?["password"] as? String
                completion(password, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    // Método para guardar transcripción con soporte para imagen local
    func saveTranscription(
        username: String,
        text: String,
        date: Date,
        tags: String,
        imageLocalPaths: [String]? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        generateEmbedding(from: text) { embedding in
            guard let embedding = embedding else {
                completion(NSError(domain: "EmbeddingError", code: 0, userInfo: nil))
                return
            }
            
            let transcription: [String: Any] = [
                "text": text,
                "date": date,
                "tags": tags,
                "imageLocalPaths": imageLocalPaths ?? [],
                "imageURLs": [] as [String],
                "audioURL": "",
                "embedding": embedding // Agregar el embedding
            ]
            
            self.db.collection("users").document(username).collection("transcriptions").addDocument(data: transcription) { error in
                completion(error)
            }
        }
    }
    
    // Método para obtener transcripciones
    func fetchTranscriptions(username: String, completion: @escaping ([Transcription]?, Error?) -> Void) {
        db.collection("users").document(username).collection("transcriptions").getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
            } else {
                let transcriptions = snapshot?.documents.compactMap { document -> Transcription? in
                    try? document.data(as: Transcription.self)
                }
                completion(transcriptions, nil)
            }
        }
    }
    
    // Método para actualizar una transcripción con soporte para imagen local
    func updateTranscription(
        username: String,
        transcriptionId: String,
        text: String,
        tags: String,
        imageLocalPaths: [String]? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        var updateData: [String: Any] = [
            "text": text,
            "tags": tags
        ]
        
        updateData["imageLocalPaths"] = imageLocalPaths ?? []
        updateData["imageURLs"] = [] as [String]
        
        db.collection("users").document(username).collection("transcriptions").document(transcriptionId).updateData(updateData) { error in
            completion(error)
        }
    }
    
    // Método para eliminar una transcripción
    func deleteTranscription(username: String, transcriptionId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(username).collection("transcriptions").document(transcriptionId).delete { error in
            completion(error)
        }
    }
}
