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

struct TranscriptionSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [TranscriptionResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    struct TranscriptionResult: Identifiable, Equatable {
        let id: String
        let text: String
        let date: Date
        let tags: String?
        
        // Método de comparación
        static func == (lhs: TranscriptionResult, rhs: TranscriptionResult) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.text == rhs.text &&
                   lhs.date == rhs.date &&
                   lhs.tags == rhs.tags
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
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
            .navigationTitle("Buscar Transcripciones")
            .animation(.default, value: searchResults)
            .animation(.default, value: isSearching)
        }
    }
    
    // Vista de resultados con manejo de estados
    private var searchResultsView: some View {
        Group {
            if isSearching {
                ProgressView("Buscando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchResults.isEmpty {
                List(searchResults) { result in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.text)
                            .font(.body)
                        
                        HStack {
                            Text(result.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let tags = result.tags, !tags.isEmpty {
                                Text(tags)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                .transition(.slide)
            } else if !searchText.isEmpty {
                Text("No se encontraron transcripciones")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.default, value: searchResults)
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
        var results: [TranscriptionResult] = []
        let group = DispatchGroup()
        
        ids.forEach { id in
            group.enter()
            db.collectionGroup("transcriptions")
                .whereField("username", isEqualTo: currentUser)
                .whereField(FieldPath.documentID(), isEqualTo: id)
                .getDocuments { snapshot, error in
                    defer { group.leave() }
                    
                    guard let document = snapshot?.documents.first,
                          let text = document.data()["text"] as? String,
                          let date = document.data()["date"] as? Timestamp else {
                        return
                    }
                    
                    let result = TranscriptionResult(
                        id: document.documentID,
                        text: text,
                        date: date.dateValue(),
                        tags: document.data()["tags"] as? String
                    )
                    
                    results.append(result)
                }
        }
        
        group.notify(queue: .main) {
            self.searchResults = results
            self.isSearching = false
            
            if results.isEmpty {
                self.errorMessage = "No se encontraron transcripciones"
            }
        }
    }
    
    struct SearchBar: View {
        @Binding var text: String
        var onSearchButtonClicked: (() -> Void)?
        
        var body: some View {
            HStack {
                TextField("Buscar transcripciones", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onSearchButtonClicked?()
                    }
                
                Button(action: {
                    onSearchButtonClicked?()
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
            .padding()
        }
    }
}
