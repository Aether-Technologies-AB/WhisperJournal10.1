
import Foundation
import FirebaseFirestoreSwift
import UIKit

struct Transcription: Codable, Identifiable, Hashable  {
    @DocumentID var id: String?
    var text: String
    var date: Date
    var tags: String
    var audioURL: String?
    var imageURL: String? // Mantener este campo por compatibilidad
    var imageLocalPath: String? // NUEVO CAMPO: Aquí se guardará la ruta local de la imagen

    // Actualizar el inicializador para incluir el nuevo campo
    init(id: String? = nil, text: String, date: Date, tags: String, audioURL: String? = nil, imageURL: String? = nil, imageLocalPath: String? = nil) {
        self.id = id
        self.text = text
        self.date = date
        self.tags = tags
        self.audioURL = audioURL
        self.imageURL = imageURL
        self.imageLocalPath = imageLocalPath // Agregar este campo
    }
    
    // El método isValid() se mantiene igual
    func isValid() -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               text.count <= 10000 &&
               date <= Date()
    }
}
