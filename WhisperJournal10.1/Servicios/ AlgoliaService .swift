//
//   AlgoliaService .swift
//  WhisperJournal10.1
//
//  Created by andree on 1/03/25.
//

import Foundation
import AlgoliaSearchClient
import FirebaseFirestore
import FirebaseAuth

class AlgoliaService {
    static let shared = AlgoliaService()
    private let index: Index
    
    struct TranscriptionRecord: Encodable {
        let objectID: ObjectID
        let text: String
        let username: String
        let date: TimeInterval
        let tags: String
        
        enum CodingKeys: String, CodingKey {
            case objectID = "objectID"
            case text, username, date, tags
        }
    }
    
    private init() {
        let client = SearchClient(appID: AlgoliaConfig.appID, apiKey: AlgoliaConfig.apiKey)
        self.index = client.index(withName: AlgoliaConfig.indexName)
        
        let settings = Settings()
            .set(\.searchableAttributes, to: ["text", "tags"])
            .set(\.attributesForFaceting, to: ["filterOnly(username)"])
            .set(\.customRanking, to: [.desc("date")])
        
        index.setSettings(settings) { result in
            switch result {
            case .success:
                print("✅ Configuración de Algolia actualizada")
            case .failure(let error):
                print("❌ Error configurando Algolia: \(error)")
            }
        }
    }

    func indexTranscription(id: String, text: String, username: String, date: Date, tags: String? = nil) {
        let objectID = ObjectID(rawValue: id)
        print("📝 Indexando transcripción: \(id)")
        
        let record = TranscriptionRecord(
            objectID: objectID,
            text: text.lowercased(),
            username: username.lowercased(),
            date: date.timeIntervalSince1970,
            tags: tags?.lowercased() ?? ""
        )
        
        index.saveObject(record) { result in
            switch result {
            case .success:
                print("✅ Transcripción indexada: \(id)")
            case .failure(let error):
                print("❌ Error indexando: \(error)")
            }
        }
    }
    
    func deleteTranscriptionFromIndex(id: String, completion: @escaping (Error?) -> Void) {
        let objectID = ObjectID(rawValue: id)
        print("🗑 Eliminando transcripción: \(id)")
        
        index.deleteObject(withID: objectID) { result in
            switch result {
            case .success:
                print("✅ Transcripción eliminada: \(id)")
                completion(nil)
            case .failure(let error):
                print("❌ Error eliminando: \(error)")
                completion(error)
            }
        }
    }
    
    func searchTranscriptions(query: String, completion: @escaping ([String]) -> Void) {
        guard let username = Auth.auth().currentUser?.email?.lowercased() else {
            print("❌ No hay usuario autenticado")
            completion([])
            return
        }
        
        print("🔍 Buscando: '\(query)' para usuario: \(username)")
        
        var searchQuery = Query(query)
        searchQuery.filters = "username:\(username)"
        searchQuery.attributesToRetrieve = ["objectID", "text", "tags"]
        searchQuery.typoTolerance = .min
        searchQuery.removeStopWords = true
        searchQuery.queryLanguages = ["es"]
        
        index.search(query: searchQuery) { result in
            switch result {
            case .success(let response):
                print("✅ Encontrados: \(response.nbHits) resultados")
                let transcriptionIDs = response.hits.compactMap { hit -> String in
                    return hit.objectID.rawValue
                }
                print("📝 IDs: \(transcriptionIDs)")
                completion(transcriptionIDs)
            case .failure(let error):
                print("❌ Error en búsqueda: \(error)")
                completion([])
            }
        }
    }
}
