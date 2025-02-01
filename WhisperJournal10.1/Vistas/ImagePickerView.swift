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
        
        // Configuraciones para prevenir modo Portrait
        if sourceType == .camera {
            // Configuración forzada para evitar modos especiales
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.allowsEditing = false
            
            // Configuración adicional para prevenir modos especiales
            if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice)
                    let session = AVCaptureSession()
                    
                    // Configuraciones de sesión para prevenir modos especiales
                    session.sessionPreset = .photo
                    session.addInput(input)
                    
                    // Imprimir información de depuración
                    print("🎥 Dispositivo de captura: \(captureDevice.localizedName)")
                    print("📷 Tipo de dispositivo: \(captureDevice.deviceType)")
                } catch {
                    print("❌ Error configurando dispositivo de captura: \(error)")
                }
            }
            
            // Forzar presentación a pantalla completa
            picker.modalPresentationStyle = .fullScreen
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
                // Intentar normalizar la imagen
                if let normalizedImage = normalizeImage(uiImage) {
                    parent.selectedImage = normalizedImage
                } else {
                    parent.selectedImage = uiImage
                }
                
                print("✅ Imagen capturada:")
                print("📏 Tamaño: \(uiImage.size)")
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Función para normalizar la imagen
        private func normalizeImage(_ image: UIImage) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return normalizedImage
        }
    }
}
