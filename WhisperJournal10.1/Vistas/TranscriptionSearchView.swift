//
//  TranscriptionSearchView.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/03/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// SearchBar como componente separado
struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(NSLocalizedString("search_placeholder", comment: ""), text: $text)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        onSearchButtonClicked()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !text.isEmpty {
                Button(NSLocalizedString("search_button", comment: "")) {
                    isFocused = false
                    onSearchButtonClicked()
                }
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .animation(.default, value: text)
    }
}

struct TranscriptionSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Transcription] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var isMigrating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                // Botón de migración
                Button(action: migrateData) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(NSLocalizedString("reindex_button", comment: ""))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
                .disabled(isMigrating)
                
                // Mostrar mensaje de error si existe
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .transition(.move(edge: .top))
                }
                
                // Vista de resultados separada
                searchResultsView
            }
            .navigationTitle(NSLocalizedString("search_title", comment: ""))
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // Vista de resultados con manejo de estados
    private var searchResultsView: some View {
        Group {
            if isMigrating {
                ProgressView(NSLocalizedString("reindexing", comment: ""))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isSearching {
                ProgressView(NSLocalizedString("searching", comment: ""))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchResults.isEmpty {
                List(searchResults) { transcription in
                    NavigationLink {
                        TranscriptDetailView(transcription: transcription)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(transcription.text)
                                .font(.body)
                                .lineLimit(2)
                            
                            HStack {
                                Text(transcription.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if !transcription.tags.isEmpty {
                                    Text(transcription.tags)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            
                            if let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty {
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundColor(.blue)
                                    Text(String(format: NSLocalizedString("detail_image_count", comment: ""), imagePaths.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .transition(.slide)
            } else if !searchText.isEmpty {
                Text(NSLocalizedString("no_results", comment: ""))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.default, value: searchResults)
    }
    
    private func migrateData() {
        isMigrating = true
        errorMessage = nil
        
        FirestoreService.shared.migrateExistingTranscriptionsToAlgolia { error in
            DispatchQueue.main.async {
                isMigrating = false
                if let error = error {
                    errorMessage = "Error al reindexar: \(error.localizedDescription)"
                } else {
                    errorMessage = "✅ Transcripciones reindexadas exitosamente"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        errorMessage = nil
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        errorMessage = nil
        
        AlgoliaService.shared.searchTranscriptions(query: searchText) { transcriptionIDs in
            if transcriptionIDs.isEmpty {
                DispatchQueue.main.async {
                    self.errorMessage = "No se encontraron resultados para '\(searchText)'"
                    self.isSearching = false
                }
                return
            }
            
            fetchTranscriptionDetails(ids: transcriptionIDs)
        }
    }
    
    private func fetchTranscriptionDetails(ids: [String]) {
        guard !ids.isEmpty,
              let currentUser = Auth.auth().currentUser?.email else {
            DispatchQueue.main.async {
                self.errorMessage = "No se pudo realizar la búsqueda"
                self.isSearching = false
            }
            return
        }
        
        let db = Firestore.firestore()
        var results: [Transcription] = []
        let group = DispatchGroup()
        
        ids.forEach { id in
            group.enter()
            
            let docRef = db.collection("users")
                .document(currentUser)
                .collection("transcriptions")
                .document(id)
            
            docRef.getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ Error obteniendo documento: \(error)")
                    return
                }
                
                guard let document = document,
                      document.exists else {
                    print("❌ Documento no encontrado: \(id)")
                    return
                }
                
                if let data = document.data() {
                    let transcription = Transcription(
                        id: document.documentID,
                        text: data["text"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        tags: data["tags"] as? String ?? "",
                        audioURL: data["audioURL"] as? String,
                        imageURLs: data["imageURLs"] as? [String],
                        imageLocalPaths: data["imageLocalPaths"] as? [String]
                    )
                    results.append(transcription)
                    print("✅ Transcripción encontrada: \(id)")
                } else {
                    print("❌ No se encontraron datos para la transcripción: \(id)")
                }
            }
        }
        
        group.notify(queue: .main) {
            self.searchResults = results.sorted(by: { $0.date > $1.date })
            self.isSearching = false
            
            if results.isEmpty {
                self.errorMessage = "No se encontraron transcripciones"
            } else {
                print("✅ Total transcripciones encontradas: \(results.count)")
            }
        }
    }
}
