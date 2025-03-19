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
    
    
}
