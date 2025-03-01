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
    static let apiKey = APIKey(rawValue: "")
    static let searchAPIKey = APIKey(rawValue: "")
    
    static let indexName = IndexName(rawValue: "Whisper_recorder_posts")
    
    static var searchClient: SearchClient {
        return SearchClient(appID: appID, apiKey: searchAPIKey)
    }
    
    static var index: Index {
        return searchClient.index(withName: indexName)
    }
}
