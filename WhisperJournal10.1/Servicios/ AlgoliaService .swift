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
    
    // Usar el índice para indexación
    private let index: Index = AlgoliaConfig.indexingIndex
    
    // Struct Encodable para indexación
    struct TranscriptionRecord: Encodable {
        let objectID: String
        let text: String
        let username: String
        let date: TimeInterval
        let tags: String
        
        enum CodingKeys: String, CodingKey {
            case objectID = "objectID"
            case text, username, date, tags
        }
    }
    
    private init() {}

    func indexTranscription(
        id: String,
        text: String,
        username: String,
        date: Date,
        tags: String? = nil
    ) {
        let record = TranscriptionRecord(
            objectID: id,
            text: text.lowercased(),  // Convertir a minúsculas
            username: username,
            date: date.timeIntervalSince1970,
            tags: tags?.lowercased() ?? ""
        )
        
        index.saveObject(record) { result in
            switch result {
            case .success:
                print("✅ Transcripción indexada en Algolia:")
                print("ID: \(id)")
                print("Texto: \(text)")
                print("Usuario: \(username)")
            case .failure(let error):
                print("❌ Error indexando en Algolia: \(error)")
            }
        }
    }
    
    func searchTranscriptions(
        query: String,
        completion: @escaping ([String]) -> Void
    ) {
        guard let username = Auth.auth().currentUser?.email else {
            print("No user is authenticated.")
            completion([])
            return
        }
        
        let searchIndex = AlgoliaConfig.searchIndex
        
        // Configuraciones de búsqueda
        var searchQuery = Query(query.lowercased())
        searchQuery.typoTolerance = .min
        searchQuery.removeStopWords = true
        searchQuery.attributesToRetrieve = ["objectID", "text"]
        searchQuery.filters = "(username:'\(username)' OR username:\"\(username)\")"
        
        print("🔍 Realizando búsqueda en Algolia con los siguientes parámetros:")
        print("App ID: \(AlgoliaConfig.appID.rawValue)")
        print("Admin API Key: \(AlgoliaConfig.apiKey.rawValue)")
        print("Query: \(searchQuery.query ?? "")")
        print("Filters: \(searchQuery.filters ?? "")")
        
        searchIndex.search(query: searchQuery) { result in
            switch result {
            case .success(let response):
                print("🔍 Búsqueda en Algolia:")
                print("Total hits: \(response.nbHits)")
                print("Parámetros: \(response.params)")
                
                let transcriptionIDs = response.hits.compactMap { hit -> String? in
                    if let dict = hit.object as? [String: Any],
                       let objectID = dict["objectID"] as? String {
                        return objectID
                    }
                    return nil
                }
                
                print("IDs encontrados: \(transcriptionIDs)")
                completion(transcriptionIDs)
                
            case .failure(let error):
                print("❌ Error buscando en Algolia: \(error.localizedDescription)")
                completion([])
            }
        }
    }
}
