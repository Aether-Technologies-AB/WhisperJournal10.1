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
import AVFoundation

struct EditTranscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var transcription: Transcription
    
    // Estados para manejo de imagen
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Nuevo estado para rastrear la fuente de imagen
    @State private var currentImageSource: ImageSource = .none
    
    // Enum para definir claramente el origen de la imagen
    enum ImageSource {
        case camera
        case photoLibrary
        case none
    }
    
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
                
                // Sección de imágenes
                Section(header: Text(NSLocalizedString("transcription_images", comment: "Images section header"))) {
                    // Mostrar imágenes locales existentes
                    if let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(imagePaths, id: \.self) { imagePath in
                                    if let image = PersistenceController.shared.loadImage(filename: imagePath) {
                                        VStack {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            
                                            Button(action: {
                                                removeImage(imagePath)
                                            }) {
                                                Text(NSLocalizedString("remove_image", comment: "Remove image"))
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Mostrar imágenes seleccionadas nuevas
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                        .padding(4)
                                }
                            }
                        }
                    }
                    
                    // Botones para seleccionar imágenes
                    HStack(spacing: 15) {
                        // Botón de Biblioteca de Fotos
                        Button(action: {
                            openImagePicker(source: .photoLibrary)
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
                            .contentShape(Rectangle())  // Área táctil exacta
                        }
                        
                        // Botón de Cámara
                        Button(action: {
                            openImagePicker(source: .camera)
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
                            .contentShape(Rectangle())  // Área táctil exacta
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
                    title: Text(alertMessage),
                    message: nil,
                    dismissButton: .default(Text(NSLocalizedString("ok_button", comment: "OK button")))
                )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(
                selectedImage: Binding(
                    get: { nil },
                    set: { newImage in
                        print("🖼️ Imagen recibida desde \(currentImageSource)")
                        if let newImage = newImage {
                            selectedImages = [newImage]
                            // Resetear después de seleccionar
                            currentImageSource = .none
                        }
                    }
                ),
                sourceType: imagePickerSourceType
            )
        }
    }
    
    private func saveTranscription() {
        guard let username = Auth.auth().currentUser?.email,
              let transcriptionId = transcription.id else { return }
        
        // Guardar imágenes seleccionadas
        var newImageLocalPaths: [String] = transcription.imageLocalPaths ?? []
        
        for selectedImage in selectedImages {
            if let imageName = PersistenceController.shared.saveImage(selectedImage) {
                newImageLocalPaths.append(imageName)
            }
        }
        
        // Actualizar transcripción en Firestore
        FirestoreService.shared.updateTranscription(
            username: username,
            transcriptionId: transcriptionId,
            text: transcription.text,
            tags: transcription.tags,
            imageLocalPaths: newImageLocalPaths.isEmpty ? nil : newImageLocalPaths
        ) { error in
            if let error = error {
                print("Error actualizando transcripción: \(error.localizedDescription)")
            } else {
                transcription.imageLocalPaths = newImageLocalPaths
                onSave(transcription)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func removeImage(_ imagePath: String) {
        guard let username = Auth.auth().currentUser?.email,
              let transcriptionId = transcription.id else { return }
        
        // Eliminar imagen local
        PersistenceController.shared.deleteImage(filename: imagePath)
        
        // Actualizar transcripción en Firestore
        var updatedImagePaths = transcription.imageLocalPaths ?? []
        updatedImagePaths.removeAll { $0 == imagePath }
        
        FirestoreService.shared.updateTranscription(
            username: username,
            transcriptionId: transcriptionId,
            text: transcription.text,
            tags: transcription.tags,
            imageLocalPaths: updatedImagePaths.isEmpty ? nil : updatedImagePaths
        ) { error in
            if let error = error {
                print("Error eliminando imagen: \(error.localizedDescription)")
            } else {
                transcription.imageLocalPaths = updatedImagePaths
            }
        }
    }
    
    private func openImagePicker(source: ImageSource) {
        showImagePicker = false
        showAlert = false
        
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        let libraryAvailable = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        
        switch source {
        case .camera:
            guard cameraAvailable else {
                showAlert = true
                alertMessage = NSLocalizedString("camera_not_available", comment: "")
                return
            }
            currentImageSource = .camera
            imagePickerSourceType = .camera
            
        case .photoLibrary:
            guard libraryAvailable else {
                showAlert = true
                alertMessage = NSLocalizedString("photo_library_not_available", comment: "")
                return
            }
            currentImageSource = .photoLibrary
            imagePickerSourceType = .photoLibrary
            
        case .none:
            return
        }
        
        showImagePicker = true
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
}
