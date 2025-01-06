//
//  TranscriptionListView.swift
//  WhisperJournal10.1
//
//  Created by andree on 15/12/24.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct TranscriptionListView: View {
    @State private var transcriptions: [Transcription] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando transcripciones...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List {
                    ForEach(transcriptions) { transcription in
                        VStack(alignment: .leading) {
                            Text(transcription.text)
                                .font(.headline)
                            Text(transcription.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if !transcription.tags.isEmpty {
                                Text("Tags: \(transcription.tags)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Transcripciones Guardadas")
            }
        }
        .onAppear(perform: loadTranscriptions)
    }
    
    private func loadTranscriptions() {
        guard let username = Auth.auth().currentUser?.email else {
            errorMessage = "No se encontró usuario autenticado"
            isLoading = false
            return
        }
        
        FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
            } else if let transcriptions = transcriptions {
                self.transcriptions = transcriptions.sorted(by: { $0.date > $1.date })
            } else {
                errorMessage = "No se encontraron transcripciones"
            }
        }
    }
}
