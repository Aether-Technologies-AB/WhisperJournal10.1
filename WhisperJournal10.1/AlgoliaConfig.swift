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
    static let appID = ApplicationID(rawValue: "86B7PTFF9V")
    static let apiKey = APIKey(rawValue: "de317a218a24f11e2ead16dc2b5e2a0e")  // Cambia a tu Admin API Key
    static let searchAPIKey = APIKey(rawValue: "dbaef478e7cb46b7cc64693f90342038")  // Cambia a tu Search API Key
    static let indexName = IndexName(rawValue: "Transcriptions")
    

}
