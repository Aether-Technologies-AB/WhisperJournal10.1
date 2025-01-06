//
//  Transcription.swift
//  WhisperJournal10.1
//
//  Created by andree on 4/01/25.
//


import Foundation
import FirebaseFirestoreSwift

struct Transcription: Identifiable, Codable {
    @DocumentID var id: String?
    var text: String
    var date: Date
    var tags: String
}
