//
//  APIKeys.swift
//  WhisperJournal10.1
//
//  Created by andree on 17/03/25.
//

import Foundation

enum APIKeys {
    // OpenAI
    static let openAI: String = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["OPENAI_API_KEY"] as? String
        else {
            fatalError("No se pudo cargar la API key de OpenAI")
        }
        return key
    }()
    
    // Algolia
    static let algoliaAppID: String = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let id = dict["ALGOLIA_APP_ID"] as? String
        else {
            fatalError("No se pudo cargar Algolia App ID")
        }
        return id
    }()
    
    static let algoliaAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["ALGOLIA_API_KEY"] as? String
        else {
            fatalError("No se pudo cargar Algolia API Key")
        }
        return key
    }()
    
    static let algoliaSearchAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["ALGOLIA_SEARCH_API_KEY"] as? String
        else {
            fatalError("No se pudo cargar Algolia Search API Key")
        }
        return key
    }()
}
