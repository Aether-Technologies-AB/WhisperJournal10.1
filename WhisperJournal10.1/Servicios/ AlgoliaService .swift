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
    
    private init() {
        let client = SearchClient(appID: AlgoliaConfig.appID, apiKey: AlgoliaConfig.apiKey)
        index = client.index(withName: AlgoliaConfig.indexName)
    }
    
    func indexTranscription(
        id: String,
        text: String,
        username: String,
        date: Date,
        tags: String? = nil
    ) {
        let record = TranscriptionRecord(
            objectID: id,
            text: text,
            username: username,
            date: date.timeIntervalSince1970,
            tags: tags ?? ""
        )
        
        index.saveObject(record) { result in
            switch result {
            case .success:
                print("Transcripción indexada en Algolia")
            case .failure(let error):
                print("Error indexando en Algolia: \(error)")
            }
        }
    }
    
    func searchTranscriptions(
        query: String,
        completion: @escaping ([String]) -> Void
    ) {
        guard let username = Auth.auth().currentUser?.email else {
            completion([])
            return
        }
        
        // Crear un Query con filtro de usuario
        var searchQuery = Query(query)
        searchQuery.filters = "username:\"\(username)\""
        
        index.search(query: searchQuery) { result in
            switch result {
            case .success(let response):
                print("🔍 Búsqueda en Algolia:")
                print("Total hits: \(response.nbHits)")
                
                let transcriptionIDs = response.hits.compactMap { hit -> String? in
                    // Depuración: imprimir cada hit
                    print("Hit: \(hit.object)")
                    
                    if let dict = hit.object as? [String: Any],
                       let objectID = dict["objectID"] as? String {
                        return objectID
                    }
                    return nil
                }
                
                print("IDs encontrados: \(transcriptionIDs)")
                completion(transcriptionIDs)
                
            case .failure(let error):
                print("❌ Error buscando en Algolia: \(error)")
                completion([])
            }
        }
    }
    }
