//
//  ImagePickerView.swift
//  WhisperJournal10.1
//
//  Created by andree on 24/01/25.
//

import SwiftUI
import UIKit
import AVFoundation

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen

        // Configuración de la cámara
        if sourceType == .camera {
            // Verificar si la cámara está disponible
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.cameraCaptureMode = .photo
                
                // Configurar la cámara trasera o frontal
                if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                    picker.cameraDevice = .rear
                } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                    picker.cameraDevice = .front
                }
            } else {
                // Si la cámara no está disponible, mostrar un mensaje de error
                print("⚠️ Cámara no disponible en este dispositivo.")
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }

        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            // Depuración: Mostrar información de la imagen
            print("🖼 Información de imagen recibida:")
            info.keys.forEach { key in
                print("🔑 Clave: \(key), Valor: \(info[key] ?? "nil")")
            }
            
            if let uiImage = info[.originalImage] as? UIImage {
                // Normalizar y comprimir la imagen
                parent.selectedImage = normalizeAndCompressImage(uiImage)
                print("✅ Imagen capturada con tamaño: \(parent.selectedImage?.size ?? .zero)")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Función para normalizar y comprimir la imagen
        private func normalizeAndCompressImage(_ image: UIImage) -> UIImage? {
            let maxSize: CGFloat = 1024  // Tamaño máximo permitido
            
            // Ajustar el tamaño manteniendo la proporción
            var newSize = image.size
            let scaleFactor = min(maxSize / newSize.width, maxSize / newSize.height)
            
            if scaleFactor < 1 {
                newSize = CGSize(width: newSize.width * scaleFactor, height: newSize.height * scaleFactor)
            }

            // Renderizar la imagen con el nuevo tamaño
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage ?? image
        }
    }
}
