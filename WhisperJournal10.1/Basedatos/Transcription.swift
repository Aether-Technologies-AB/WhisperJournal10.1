import Foundation
import FirebaseFirestoreSwift

struct Transcription: Codable, Identifiable, Hashable {
struct Transcription: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let date: Date
    let tags: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case tags
    }
    var audioURL: String? // Opcional para guardar URL de audio
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case date
        case tags
        case audioURL
    }
    
    // Inicializador personalizado
    init(id: String? = nil, text: String, date: Date, tags: String, audioURL: String? = nil) {
        self.id = id
        self.text = text
        self.date = date
        self.tags = tags
        self.audioURL = audioURL
    }
    
    // Método para validar transcripción
    func isValid() -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               text.count <= 10000 &&
               date <= Date()
    }
}
}