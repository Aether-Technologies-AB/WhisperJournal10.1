



import Foundation
import FirebaseFirestoreSwift
import UIKit

struct Transcription: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var text: String
    var date: Date
    var tags: String
    var audioURL: String?
    var imageURLs: [String]? // Cambiar a array
    var imageLocalPaths: [String]? // Cambiar a array
    var embedding: [Float]? // Agregar campo para almacenar el embedding

    // Actualizar inicializador
    init(id: String? = nil, text: String, date: Date, tags: String, audioURL: String? = nil, imageURLs: [String]? = nil, imageLocalPaths: [String]? = nil, embedding: [Float]? = nil) {
        self.id = id
        self.text = text
        self.date = date
        self.tags = tags
        self.audioURL = audioURL
        self.imageURLs = imageURLs
        self.imageLocalPaths = imageLocalPaths
        self.embedding = embedding // Inicializar el embedding
    }
    
    // Corregir método isValid()
    func isValid() -> Bool {
        return !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               self.text.count <= 10000 &&
               self.date <= Date()
    }
}

