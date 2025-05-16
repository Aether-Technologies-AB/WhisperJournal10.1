//
//  TranscriptDetailView.swift
//  WhisperJournal10.1
//
//  Created by andree on 15/12/24.
//

import SwiftUI
import FirebaseFirestore
import UIKit

struct TranscriptDetailView: View {
    let transcription: Transcription
    @State private var loadedImages: [UIImage] = []
    @State private var isLoadingImages = false
    @State private var errorMessage: String? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Texto de la transcripción
                Group {
                    Text(NSLocalizedString("detail_transcription_label", comment: ""))
                        .font(.headline)
                    Text(transcription.text)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Fecha
                Group {
                    Text(NSLocalizedString("detail_date_label", comment: ""))
                        .font(.headline)
                    Text(transcription.date, style: .date)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Etiquetas
                if !transcription.tags.isEmpty {
                    Group {
                        Text(NSLocalizedString("detail_tags_label", comment: ""))
                            .font(.headline)
                        Text(transcription.tags)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                // Imágenes
                if let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty {
                    Group {
                        Text(NSLocalizedString("detail_images_label", comment: ""))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoadingImages {
                            ProgressView(NSLocalizedString("detail_loading_images", comment: ""))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if !loadedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(loadedImages, id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 200)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(NSLocalizedString("detail_title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        // Gesto de deslizamiento hacia abajo para cerrar la vista
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Solo permitir deslizamiento hacia abajo
                    if gesture.translation.height > 0 {
                        self.dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    // Si el deslizamiento es suficientemente largo hacia abajo, cerrar la vista
                    if gesture.translation.height > 100 {
                        self.presentationMode.wrappedValue.dismiss()
                    } else {
                        // Si no es suficiente, volver a la posición original
                        self.dragOffset = .zero
                    }
                }
        )
        // Aplicar el efecto de deslizamiento a la vista
        .offset(y: dragOffset.height * 0.3) // Factor de amortiguación para que el movimiento sea suave
        .animation(.interactiveSpring(), value: dragOffset)
        .onAppear {
            loadImages()
        }
    }
    
    private func loadImages() {
        guard let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty else { return }
        
        isLoadingImages = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let images = imagePaths.compactMap { path -> UIImage? in
                if let image = PersistenceController.shared.loadImage(filename: path) {
                    return image
                } else {
                    print("❌ No se pudo cargar la imagen: \(path)")
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                isLoadingImages = false
                if images.isEmpty {
                    errorMessage = NSLocalizedString("detail_loading_images_error", comment: "")
                } else {
                    loadedImages = images
                }
            }
        }
    }
}
