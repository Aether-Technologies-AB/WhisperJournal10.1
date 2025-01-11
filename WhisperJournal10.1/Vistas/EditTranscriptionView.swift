//
//  EditTranscriptionView.swift
//  WhisperJournal10.1
//
//  Created by andree on 9/01/25.
//

import SwiftUI

struct EditTranscriptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var transcription: Transcription
    var onSave: (Transcription) -> Void
    
    init(transcription: Transcription, onSave: @escaping (Transcription) -> Void) {
        // Usar _transcription para inicializar el @State
        self._transcription = State(initialValue: transcription)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transcripción")) {
                    TextEditor(text: $transcription.text)
                        .frame(minHeight: 200)
                }
                
                Section(header: Text("Etiquetas")) {
                    TextField("Añadir etiquetas", text: $transcription.tags)
                }
                
                // Información adicional de solo lectura
                Section(header: Text("Información")) {
                    Text("Fecha: \(transcription.date, style: .date)")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Editar Transcripción")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Guardar") {
                    saveChanges()
                }
            )
        }
    }
    
    private func saveChanges() {
        // Validar que el texto no esté vacío
        guard !transcription.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Podrías mostrar una alerta aquí
            return
        }
        
        onSave(transcription)
        presentationMode.wrappedValue.dismiss()
    }
}
