//
//  AlgoliaConfig.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/03/25.
//
//


import Foundation
import AlgoliaSearchClient


struct AlgoliaConfig {
    static let appID = ApplicationID(rawValue: "")
    static let apiKey = APIKey(rawValue: "")  // Cambia a tu Admin API Key
    static let searchAPIKey = APIKey(rawValue: "")  // Cambia a tu Search API Key
    static let indexName = IndexName(rawValue: "Transcriptions")
    
    // Cliente para indexación (con Admin API Key)
    static var indexClient: SearchClient {
        return SearchClient(appID: appID, apiKey: apiKey)
    }
    
    // Cliente para búsquedas (con Search API Key)
    static var searchClient: SearchClient {
        return SearchClient(appID: appID, apiKey: searchAPIKey)
    }
    
    // Índice para indexación
    static var indexingIndex: Index {
        return indexClient.index(withName: indexName)
    }
    
    // Índice para búsquedas
    static var searchIndex: Index {
        return searchClient.index(withName: indexName)
    }
}
