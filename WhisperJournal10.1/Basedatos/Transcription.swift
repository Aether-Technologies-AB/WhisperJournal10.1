import Foundation
import FirebaseFirestoreSwift
import UIKit

struct Transcription: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var text: String
    var date: Date
    var tags: String
    var audioURL: String? // Opcional para guardar URL de audio
    var imageURL: String? // Nuevo campo para la URL de la imagen
    var imageData: Data? // Para almacenar la imagen localmente si es necesario
    
    // Actualiza el inicializador
    init(id: String? = nil, text: String, date: Date, tags: String, audioURL: String? = nil, imageURL: String? = nil, imageData: Data? = nil) {
        self.id = id
        self.text = text
        self.date = date
        self.tags = tags
        self.audioURL = audioURL
        self.imageURL = imageURL
        self.imageData = imageData
    }
    
    // Método para validar transcripción (actualizado)
    func isValid() -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               text.count <= 10000 &&
               date <= Date()
    }
}
