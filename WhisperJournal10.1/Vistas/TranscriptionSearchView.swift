//
//  TranscriptionSearchView.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/03/25.
//
import SwiftUI
import Firebase
import AVFoundation

struct TranscriptionSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [Transcription] = []
    @State private var errorMessage: String?
    @State private var selectedTranscription: Transcription?
    @State private var aiResponse: String?
    @State private var usedTranscriptions: [Transcription] = []
    @State private var isLoading = false
    @State private var isRecording = false
    @State private var audioURL: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                // Barra de búsqueda
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField(NSLocalizedString("ask_question", comment: ""), text: $searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                aiResponse = nil
                                usedTranscriptions = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Botón de micrófono
                        Button(action: handleVoiceSearch) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundColor(isRecording ? .red : .blue)
                                .font(.system(size: 24))
                        }
                        .padding(.horizontal, 4)
                        
                        if isRecording {
                            Image(systemName: "waveform")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView(NSLocalizedString("searching", comment: ""))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Mostrar respuesta de IA si existe
                            if let response = aiResponse {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(NSLocalizedString("ai_response_title", comment: ""))
                                        .font(.headline)
                                    Text(response)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                
                                if !usedTranscriptions.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(NSLocalizedString("based_on_entries", comment: ""))
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(usedTranscriptions) { transcription in
                                            TranscriptionResultRow(transcription: transcription)
                                                .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            
                            // Mostrar otros resultados de búsqueda
                            if !searchResults.isEmpty {
                                Text(NSLocalizedString("other_related_results", comment: ""))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                ForEach(searchResults) { transcription in
                                    if !usedTranscriptions.contains(transcription) {
                                        TranscriptionResultRow(transcription: transcription)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(NSLocalizedString("search_title", comment: ""), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("close_button", comment: "")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func handleVoiceSearch() {
        if isRecording {
            // Detener grabación
            AudioSessionManager.shared.stopRecording()
            isRecording = false
            
            // Transcribir el audio con detección automática de idioma
            if let url = audioURL {
                isLoading = true
                WhisperService.shared.transcribeAudio(at: url, language: "") { transcription in
                    DispatchQueue.main.async {
                        if let transcription = transcription {
                            self.searchText = transcription
                            self.performSearch()
                        }
                        self.isLoading = false
                    }
                }
            }
        } else {
            // Iniciar grabación
            audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("search_audio.m4a")
            if let url = audioURL {
                AudioSessionManager.shared.startRecording(to: url)
                isRecording = true
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        aiResponse = nil
        searchResults = []
        usedTranscriptions = []
        
        // Primero intentamos la búsqueda conversacional
        ConversationalSearchService.shared.performConversationalSearch(query: searchText) { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error en búsqueda conversacional: \(error)")
                    self.errorMessage = "Error en la búsqueda: \(error.localizedDescription)"
                } else if let response = response {
                    self.aiResponse = response.answer
                    self.usedTranscriptions = response.usedTranscriptions
                }
                self.isLoading = false
            }
        }
        
        // También realizamos la búsqueda normal con Algolia
        AlgoliaService.shared.searchTranscriptions(query: searchText) { transcriptionIDs in
            guard let username = Auth.auth().currentUser?.email else {
                DispatchQueue.main.async {
                    self.errorMessage = "Usuario no autenticado"
                    self.isLoading = false
                }
                return
            }
            
            FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error en búsqueda Algolia: \(error)")
                        self.errorMessage = "Error en la búsqueda: \(error.localizedDescription)"
                    } else if let transcriptions = transcriptions {
                        self.searchResults = transcriptions.filter { transcription in
                            guard let id = transcription.id else { return false }
                            return transcriptionIDs.contains(id)
                        }.sorted(by: { $0.date > $1.date })
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

struct TranscriptionResultRow: View {
    let transcription: Transcription
    
    var body: some View {
        NavigationLink(destination: TranscriptDetailView(transcription: transcription)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(transcription.text)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(transcription.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !transcription.tags.isEmpty {
                    Text(String(format: NSLocalizedString("tags_label", comment: ""), transcription.tags))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct TranscriptionSearchView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptionSearchView()
    }
}
