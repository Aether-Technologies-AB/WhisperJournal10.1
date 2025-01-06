import Foundation
import FirebaseFirestoreSwift

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
}
