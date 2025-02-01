//
//  Persistence.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    // Contenedor de Core Data
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WhisperJournal10_1")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configurar combinación automática de cambios
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Guardar los cambios en Core Data
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("No se pudo guardar el contexto: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // Método para guardar una transcripción
    func saveTranscript(text: String, date: Date? = nil, tags: String? = nil) {
        let context = container.viewContext
        let newTranscript = Transcript(context: context)
        newTranscript.text = text
        newTranscript.date = date ?? Date()
        newTranscript.tags = tags ?? ""
        newTranscript.timestamp = Date()
        
        do {
            try context.save()
        } catch {
            print("Error guardando transcripción: \(error)")
        }
    }

    // Obtener todas las transcripciones guardadas
    func fetchAllTranscripts() -> [Transcript] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<Transcript> = Transcript.fetchRequest()
        
        do {
            let transcripts = try context.fetch(fetchRequest)
            return transcripts
        } catch {
            print("Error al obtener las transcripciones: \(error)")
            return []
        }
    }
    
    // NUEVO MÉTODO: Guardar imagen localmente
    func saveImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Error: No se pudo convertir la imagen a datos")
            return nil
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uniqueFilename = "\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            // Crear directorio si no existe
            try FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o777]
            )
            
            // Guardar con permisos completos
            try imageData.write(to: fileURL, options: [.atomic, .completeFileProtection])
            
            print("✅ Imagen guardada en: \(fileURL.path)")
            
            // Verificar que el archivo existe y tiene datos
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            print("📦 Tamaño del archivo: \(fileSize) bytes")
            
            return uniqueFilename
        } catch {
            print("❌ Error al guardar imagen: \(error.localizedDescription)")
            print("📍 Ruta intentada: \(fileURL.path)")
            
            // Imprimir detalles del error
            if let nsError = error as NSError? {
                print("Código de error: \(nsError.code)")
                print("Dominio de error: \(nsError.domain)")
            }
            
            return nil
        }
    }
        
        // NUEVO MÉTODO: Cargar imagen desde archivo local
        func loadImage(filename: String) -> UIImage? {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            return UIImage(contentsOfFile: fileURL.path)
        }
        
        // NUEVO MÉTODO: Eliminar imagen local
    func deleteImage(filename: String) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(filename)
            
            do {
                // Verificar si el archivo existe antes de intentar eliminarlo
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Imagen eliminada con éxito: \(filename)")
                } else {
                    print("El archivo no existe: \(filename)")
                }
            } catch {
                // Manejar específicamente diferentes tipos de errores
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case NSFileNoSuchFileError:
                        print("El archivo no existe: \(filename)")
                    case NSFileWriteNoPermissionError:
                        print("No se tienen permisos para eliminar el archivo: \(filename)")
                    default:
                        print("Error eliminando imagen: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
