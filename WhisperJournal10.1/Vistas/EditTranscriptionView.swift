//
//  EditTranscriptionView.swift
//  WhisperJournal10.1
//
//  Created by andree on 11/01/25.
//
import SwiftUI

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
                
                // Nueva sección para imagen
                Section(header: Text(NSLocalizedString("transcription_image", comment: "Image section header"))) {
                    // Mostrar imagen existente o seleccionada
                    if let imageURL = transcription.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                        }
                    } else if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                    
                    // Botones para seleccionar imagen con un diseño más atractivo
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
                    // Lógica de guardado con imagen
                    if let selectedImage = selectedImage {
                        FirestoreService.shared.uploadImage(selectedImage) { imageURL in
                            transcription.imageURL = imageURL
                            onSave(transcription)
                            presentationMode.wrappedValue.dismiss()
                        }
                    } else {
                        onSave(transcription)
                        presentationMode.wrappedValue.dismiss()
                    }
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
    
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        // Verificar si la cámara está disponible
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showAlert = true
            return
        }
        
        imagePickerSourceType = sourceType
        showImagePicker = true
    }
}

struct EditTranscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        EditTranscriptionView(transcription: Transcription(text: "Sample text", date: Date(), tags: "Sample tags"), onSave: { _ in })
    }
}
