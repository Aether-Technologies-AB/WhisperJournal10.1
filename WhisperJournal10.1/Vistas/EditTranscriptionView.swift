//
//  EditTranscriptionView.swift
//  WhisperJournal10.1
//
//  Created by andree on 11/01/25.
//
import SwiftUI
import UIKit
import AVFoundation
import Photos
import FirebaseAuth

struct EditTranscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var transcription: Transcription
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    var onSave: (Transcription) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // Sección de texto existente
                Section(header: Text(NSLocalizedString("edit_transcription_text", comment: "Text section header"))) {
                    TextEditor(text: $transcription.text)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                
                // Sección de etiquetas existente
                Section(header: Text(NSLocalizedString("edit_transcription_tags", comment: "Tags section header"))) {
                    TextField(NSLocalizedString("enter_tags", comment: "Enter tags placeholder"), text: $transcription.tags)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                
                // Sección de imagen
                Section(header: Text(NSLocalizedString("transcription_image", comment: "Image section header"))) {
                    // Mostrar imagen local si existe
                    if let imageLocalPath = transcription.imageLocalPath,
                       let image = PersistenceController.shared.loadImage(filename: imageLocalPath) {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: 300)
                                .cornerRadius(10)
                            
                            // Botón para eliminar imagen
                            Button(action: {
                                // Eliminar imagen local
                                if let previousImagePath = transcription.imageLocalPath {
                                    PersistenceController.shared.deleteImage(filename: previousImagePath)
                                }
                                
                                // Limpiar referencias de imagen
                                transcription.imageLocalPath = nil
                                transcription.imageURL = nil
                                
                                // Actualizar en Firestore
                                guard let username = Auth.auth().currentUser?.email,
                                      let transcriptionId = transcription.id else { return }
                                
                                FirestoreService.shared.updateTranscription(
                                    username: username,
                                    transcriptionId: transcriptionId,
                                    text: transcription.text,
                                    tags: transcription.tags,
                                    imageLocalPath: nil
                                ) { error in
                                    if let error = error {
                                        print("Error eliminando imagen: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Text("Eliminar Imagen")
                                    .foregroundColor(.red)
                            }
                        }
                    } else if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .cornerRadius(10)
                    }
                    // Botones para seleccionar imagen
                    HStack(spacing: 15) {
                        // Botón de Biblioteca de Fotos
                        Button(action: {
                            openImagePicker(sourceType: .photoLibrary)
                        }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.blue)
                                
                                Text(NSLocalizedString("choose_from_library", comment: "Choose from library"))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                        }
                        
                        // Botón de Cámara
                        Button(action: {
                            openImagePicker(sourceType: .camera)
                        }) {
                            VStack {
                                Image(systemName: "camera")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.green)
                                
                                Text(NSLocalizedString("take_photo", comment: "Take photo"))
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                // Información adicional de solo lectura
                Section(header: Text(NSLocalizedString("edit_transcription_info", comment: "Information section header"))) {
                    Text("\(NSLocalizedString("edit_transcription_date", comment: "Date label")) \(transcription.date, style: .date)")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(NSLocalizedString("edit_transcription_title", comment: "Edit Transcription title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("edit_transcription_cancel", comment: "Cancel button")) {
                    presentationMode.wrappedValue.dismiss()
                }
                    .foregroundColor(.blue),
                trailing: Button(NSLocalizedString("edit_transcription_save", comment: "Save button")) {
                    saveTranscription()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Cámara no disponible"),
                    message: Text("No se puede acceder a la cámara en este dispositivo o simulador"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedImage, sourceType: imagePickerSourceType)
        }
    }
    
    private func saveTranscription() {
        guard let username = Auth.auth().currentUser?.email,
              let transcriptionId = transcription.id else { return }
        
        if let selectedImage = selectedImage {
            // Guardar imagen localmente
            if let imageName = PersistenceController.shared.saveImage(selectedImage) {
                // Si ya había una imagen local previa, eliminarla
                if let previousImagePath = transcription.imageLocalPath {
                    PersistenceController.shared.deleteImage(filename: previousImagePath)
                }
                
                // Actualizar transcripción con nueva ruta de imagen
                transcription.imageLocalPath = imageName
                transcription.imageURL = nil // Limpiar URL de Firebase
                
                // Actualizar en Firestore
                FirestoreService.shared.updateTranscription(
                    username: username,
                    transcriptionId: transcriptionId,
                    text: transcription.text,
                    tags: transcription.tags,
                    imageLocalPath: imageName
                ) { error in
                    if let error = error {
                        print("Error actualizando transcripción: \(error.localizedDescription)")
                    } else {
                        onSave(transcription)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } else {
            // Si no hay imagen nueva, guardar sin modificar imagen
            onSave(transcription)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        // Verificaciones de permisos y disponibilidad
        guard sourceType == .camera else {
            imagePickerSourceType = sourceType
            showImagePicker = true
            return
        }
        
        // Verificación específica para cámara
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted && UIImagePickerController.isSourceTypeAvailable(.camera) {
                    // Configuración mínima para cámara
                    imagePickerSourceType = .camera
                    showImagePicker = true
                } else {
                    showAlert = true
                }
            }
        }
    }
}

struct EditTranscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditTranscriptionView(
            transcription: Transcription(
                text: "Sample text",
                date: Date(),
                tags: "Sample tags"
            ),
            onSave: { _ in }
        )
    }
}
