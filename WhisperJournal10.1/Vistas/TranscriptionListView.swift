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
    @State private var showSearchView = false  // Nuevo estado para la vista de búsqueda
    
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
                            HStack(spacing: 12) {
                                // Reemplazar ScrollView de imágenes con un simple ícono
                                if let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty {
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(.blue)
                                        .overlay(
                                            Text("\(imagePaths.count)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(3)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                                .offset(x: 10, y: -10),
                                            alignment: .topTrailing
                                        )
                                }

                                VStack(alignment: .leading, spacing: 5) {
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
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                            // Tocar para editar
                            .onTapGesture {
                                presentEditView(for: transcription)
                            }
                            // Deslizar con estilo personalizado sin colores de fondo
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    presentEditView(for: transcription)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                }
                                .tint(.clear) // Sin color de fondo
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    deleteTranscription(transcription)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.white)
                                }
                                .tint(.clear) // Sin color de fondo
                            }
                        }
                    }
                    .navigationTitle(NSLocalizedString("saved_transcriptions_title", comment: "Saved Transcriptions title"))
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationBarItems(trailing:
                Button(action: {
                    showSearchView = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
            )
            .sheet(isPresented: $showSearchView) {
                TranscriptionSearchView()
            }
        }
        .onAppear(perform: loadTranscriptions)
    }

    private func presentEditView(for transcription: Transcription) {
        let editView = EditTranscriptionView(
            transcription: transcription,
            onSave: { updatedTranscription in
                updateTranscription(updatedTranscription)
            }
        )
        
        // Método actualizado para iOS 15+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let hostingController = UIHostingController(rootView: editView)
            rootViewController.present(
                hostingController,
                animated: true,
                completion: nil
            )
        }
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
            tags: transcription.tags,
            imageLocalPaths: transcription.imageLocalPaths
        ) { error in
            if let error = error {
                errorMessage = NSLocalizedString("error_updating_transcription", comment: "Error updating transcription") + ": \(error.localizedDescription)"
            } else {
                loadTranscriptions()
            }
        }
    }

    private func deleteTranscription(_ transcription: Transcription) {
        guard let username = Auth.auth().currentUser?.email,
              let transcriptionId = transcription.id else { return }
        
        // Eliminar imágenes locales si existen
        if let imagePaths = transcription.imageLocalPaths {
            PersistenceController.shared.deleteImages(filenames: imagePaths)
        }
        
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

struct TranscriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptionListView()
    }
}
