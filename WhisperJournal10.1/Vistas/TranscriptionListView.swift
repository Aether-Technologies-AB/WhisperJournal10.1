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
                    ProgressView(NSLocalizedString("loading_transcriptions", comment: "Loading transcriptions"))
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
                                        Text("\(NSLocalizedString("tags_label", comment: "Tags label")): \(transcription.tags)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                Spacer()
                                Menu {
                                    Button(NSLocalizedString("edit_button", comment: "Edit button")) {
                                        selectedTranscription = transcription
                                        print("Transcription selected for editing: \(selectedTranscription?.text ?? "None")")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showingEditSheet = true
                                        }
                                    }
                                    Button(NSLocalizedString("delete_button", comment: "Delete button"), role: .destructive) {
                                        selectedTranscription = transcription
                                        showingDeleteConfirmation = true
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6)) // Gris claro (systemGray6)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Gris con opacidad del 20%
                        }
                    }
                    .navigationTitle(NSLocalizedString("saved_transcriptions_title", comment: "Saved Transcriptions title"))
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
                    Text(NSLocalizedString("no_transcription_selected", comment: "No transcription selected"))
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text(NSLocalizedString("delete_transcription_title", comment: "Delete Transcription title")),
                    message: Text(NSLocalizedString("delete_transcription_message", comment: "Delete Transcription message")),
                    primaryButton: .destructive(Text(NSLocalizedString("delete_button", comment: "Delete button"))) {
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
            errorMessage = NSLocalizedString("no_authenticated_user", comment: "No authenticated user")
            isLoading = false
            return
        }
        
        isLoading = true
        FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
            isLoading = false
            if let error = error {
                errorMessage = NSLocalizedString("error_loading_transcriptions", comment: "Error loading transcriptions") + ": \(error.localizedDescription)"
            } else if let transcriptions = transcriptions {
                self.transcriptions = transcriptions.sorted(by: { $0.date > $1.date })
            } else {
                errorMessage = NSLocalizedString("no_transcriptions_found", comment: "No transcriptions found")
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
                errorMessage = NSLocalizedString("error_updating_transcription", comment: "Error updating transcription") + ": \(error.localizedDescription)"
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
                errorMessage = NSLocalizedString("error_deleting_transcription", comment: "Error deleting transcription") + ": \(error.localizedDescription)"
            } else {
                loadTranscriptions()
            }
        }
    }
}
