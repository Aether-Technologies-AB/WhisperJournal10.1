//
//  FirestoreService.swift
//  WhisperJournal10.1
//
//  Created by andree on 4/01/25.

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import UIKit
import AlgoliaSearchClient
import FirebaseAuth

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

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

    func saveTranscription(
        username: String,
        text: String,
        date: Date,
        tags: String,
        imageLocalPaths: [String]? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                // Generar embedding
                let embedding = try await EmbeddingService.shared.generateEmbedding(for: text)
                
                let transcription: [String: Any] = [
                    "text": text,
                    "date": date,
                    "tags": tags,
                    "imageLocalPaths": imageLocalPaths ?? [],
                    "imageURLs": [] as [String],
                    "audioURL": "",
                    "embedding": embedding
                ]
                
                // Cambiar el orden de declaración
                let documentRef = try await db.collection("users").document(username)
                    .collection("transcriptions")
                    .addDocument(data: transcription)
                
                try await documentRef.setData(transcription)
                
                // Indexar en Algolia después de guardar en Firestore
                AlgoliaService.shared.indexTranscription(
                    id: documentRef.documentID,
                    text: text,
                    username: username,
                    date: date,
                    tags: tags
                )
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

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
            if let error = error {
                completion(error)
                return
            }
            
            // Actualizar en Algolia después de actualizar en Firestore
            AlgoliaService.shared.indexTranscription(
                id: transcriptionId,
                text: text,
                username: username,
                date: Date(),
                tags: tags
            )
            
            completion(nil)
        }
    }
    
    func deleteTranscription(username: String, transcriptionId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(username).collection("transcriptions").document(transcriptionId).delete { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Eliminar de Algolia después de eliminar de Firestore
            AlgoliaService.shared.deleteTranscriptionFromIndex(id: transcriptionId) { error in
                completion(error)
            }
        }
    }

    // Nuevo método para migración de Algolia
    
    
    func migrateExistingTranscriptionsToAlgolia(completion: @escaping (Error?) -> Void) {
        guard let username = Auth.auth().currentUser?.email else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]))
            return
        }
        
        fetchTranscriptions(username: username) { transcriptions, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let transcriptions = transcriptions else {
                completion(nil)
                return
            }
            
            let group = DispatchGroup()
            
            transcriptions.forEach { transcription in
                guard let id = transcription.id else { return }
                
                group.enter()
                AlgoliaService.shared.indexTranscription(
                    id: id,
                    text: transcription.text,
                    username: username,
                    date: transcription.date,
                    tags: transcription.tags
                )
                
                group.leave()
            }
            
            group.notify(queue: .main) {
                completion(nil)  // Eliminamos migrationErrors ya que no los estamos usando
            }
        }
    }
    }
