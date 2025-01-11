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
    @State private var selectedTranscription: Transcription?
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
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
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transcription.text)
                                        .font(.headline)
                                        .lineLimit(2)
                                    Text(transcription.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    if !transcription.tags.isEmpty {
                                        Text("Tags: \(transcription.tags)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                Spacer()
                                Menu {
                                    Button("Editar") {
                                        selectedTranscription = transcription
                                        print("Transcription selected for editing: \(selectedTranscription?.text ?? "None")")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showingEditSheet = true
                                        }
                                    }
                                    Button("Eliminar", role: .destructive) {
                                        selectedTranscription = transcription
                                        showingDeleteConfirmation = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                            }
                        }
                    }
                    .navigationTitle("Transcripciones Guardadas")
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let transcription = selectedTranscription {
                    EditTranscriptionView(
                        transcription: transcription,
                        onSave: { updatedTranscription in
                            updateTranscription(updatedTranscription)
                        }
                    )
                } else {
                    Text("No transcription selected")
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Eliminar Transcripción"),
                    message: Text("¿Estás seguro de eliminar esta transcripción?"),
                    primaryButton: .destructive(Text("Eliminar")) {
                        deleteSelectedTranscription()
                    },
                    secondaryButton: .cancel()
                )
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
        
        isLoading = true
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

    private func updateTranscription(_ transcription: Transcription) {
        guard let username = Auth.auth().currentUser?.email,
              let transcriptionId = transcription.id else { return }
        
        FirestoreService.shared.updateTranscription(
            username: username,
            transcriptionId: transcriptionId,
            text: transcription.text,
            tags: transcription.tags
        ) { error in
            if let error = error {
                errorMessage = "Error al actualizar: \(error.localizedDescription)"
            } else {
                loadTranscriptions()
            }
        }
    }

    private func deleteSelectedTranscription() {
        guard let username = Auth.auth().currentUser?.email,
              let transcription = selectedTranscription,
              let transcriptionId = transcription.id else { return }
        
        FirestoreService.shared.deleteTranscription(
            username: username,
            transcriptionId: transcriptionId
        ) { error in
            if let error = error {
                errorMessage = "Error al eliminar: \(error.localizedDescription)"
            } else {
                loadTranscriptions()
            }
        }
    }
    }
