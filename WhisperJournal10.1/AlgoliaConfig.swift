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
    static let appID = ApplicationID(rawValue: APIKeys.algoliaAppID)
    static let apiKey = APIKey(rawValue: APIKeys.algoliaAPIKey)
    static let searchAPIKey = APIKey(rawValue: APIKeys.algoliaSearchAPIKey)
    static let indexName = IndexName(rawValue: "Transcriptions")
}
