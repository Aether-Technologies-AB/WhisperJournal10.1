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

    // Método para subir imagen a Firebase Storage
    func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let imageName = UUID().uuidString
        let imageRef = storage.reference().child("transcription_images/\(imageName).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }

    // Método actualizado para guardar transcripción con imagen opcional
    func saveTranscription(username: String, text: String, date: Date, tags: String, image: UIImage? = nil, completion: @escaping (Error?) -> Void) {
        // Si hay imagen, primero la subimos
        if let image = image {
            uploadImage(image) { [weak self] imageURL in
                let transcription: [String: Any] = [
                    "text": text,
                    "date": date,
                    "tags": tags,
                    "imageURL": imageURL ?? ""
                ]
                
                self?.db.collection("users").document(username).collection("transcriptions").addDocument(data: transcription) { error in
                    completion(error)
                }
            }
        } else {
            // Si no hay imagen, guardamos sin ella
            let transcription: [String: Any] = [
                "text": text,
                "date": date,
                "tags": tags,
                "imageURL": ""
            ]
            
            db.collection("users").document(username).collection("transcriptions").addDocument(data: transcription) { error in
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

    // Método para actualizar una transcripción con soporte para imagen
    func updateTranscription(username: String, transcriptionId: String, text: String, tags: String, image: UIImage? = nil, completion: @escaping (Error?) -> Void) {
        // Si hay imagen nueva, primero la subimos
        if let image = image {
            uploadImage(image) { [weak self] imageURL in
                let updateData: [String: Any] = [
                    "text": text,
                    "tags": tags,
                    "imageURL": imageURL ?? ""
                ]
                
                self?.db.collection("users").document(username).collection("transcriptions").document(transcriptionId).updateData(updateData) { error in
                    completion(error)
                }
            }
        } else {
            // Si no hay imagen nueva, actualizamos solo texto y tags
            let updateData: [String: Any] = [
                "text": text,
                "tags": tags
            ]
            
            db.collection("users").document(username).collection("transcriptions").document(transcriptionId).updateData(updateData) { error in
                completion(error)
            }
        }
    }
    
    // Método para eliminar una transcripción
    func deleteTranscription(username: String, transcriptionId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(username).collection("transcriptions").document(transcriptionId).delete { error in
            completion(error)
        }
    }
}
