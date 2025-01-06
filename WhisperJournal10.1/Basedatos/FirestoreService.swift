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
}
