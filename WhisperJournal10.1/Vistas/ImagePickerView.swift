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
        
        // Configuraciones universales
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        
        // Configuración específica para cámara
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
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
            // Depuración exhaustiva
            print("🖼 Información de imagen recibida:")
            info.keys.forEach { key in
                print("🔑 Clave: \(key), Valor: \(info[key] ?? "nil")")
            }
            
            if let uiImage = info[.originalImage] as? UIImage {
                // Normalizar y comprimir la imagen
                if let normalizedImage = normalizeAndCompressImage(uiImage) {
                    parent.selectedImage = normalizedImage
                } else {
                    parent.selectedImage = uiImage
                }
                
                print("✅ Imagen capturada:")
                print("📏 Tamaño original: \(uiImage.size)")
                print("📏 Tamaño normalizada: \(parent.selectedImage?.size ?? .zero)")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Función para normalizar y comprimir la imagen
        private func normalizeAndCompressImage(_ image: UIImage) -> UIImage? {
            // Tamaño máximo para la imagen (ajusta según necesites)
            let maxSize: CGFloat = 1024
            
            // Calcular nuevo tamaño manteniendo proporción
            var newSize = image.size
            if newSize.width > maxSize || newSize.height > maxSize {
                let scaleFactor = min(maxSize / newSize.width, maxSize / newSize.height)
                newSize = CGSize(width: newSize.width * scaleFactor, height: newSize.height * scaleFactor)
            }
            
            // Renderizar imagen con nuevo tamaño
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage
        }
    }
}
