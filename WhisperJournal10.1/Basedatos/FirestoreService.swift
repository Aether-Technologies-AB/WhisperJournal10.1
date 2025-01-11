//
//  FirestoreService.swift
//  WhisperJournal10.1
//
//  Created by andree on 4/01/25.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

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

    func saveTranscription(username: String, text: String, date: Date, tags: String, completion: @escaping (Error?) -> Void) {
        let transcription = ["text": text, "date": date, "tags": tags] as [String : Any]
        db.collection("users").document(username).collection("transcriptions").addDocument(data: transcription) { error in
            completion(error)
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
    // Método para actualizar una transcripción
        func updateTranscription(username: String, transcriptionId: String, text: String, tags: String, completion: @escaping (Error?) -> Void) {
            let updateData: [String: Any] = [
                "text": text,
                "tags": tags
            ]
            
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
