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
    var onSave: (Transcription) -> Void

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text(NSLocalizedString("edit_transcription_text", comment: "Text section header"))) {
                        TextEditor(text: $transcription.text)
                            .frame(minHeight: 200)
                            .padding()
                            .background(Color(.systemGray6)) // Gris claro (systemGray6)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Gris con opacidad del 20%
                    }
                    
                    Section(header: Text(NSLocalizedString("edit_transcription_tags", comment: "Tags section header"))) {
                        TextField(NSLocalizedString("enter_tags", comment: "Enter tags placeholder"), text: $transcription.tags)
                            .padding()
                            .background(Color(.systemGray6)) // Gris claro (systemGray6)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Gris con opacidad del 20%
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
                    .foregroundColor(.blue), // Color del Texto del Botón de Cancelar: Azul
                    trailing: Button(NSLocalizedString("edit_transcription_save", comment: "Save button")) {
                        saveChanges()
                    }
                    .foregroundColor(.white) // Color del Texto del Botón de Guardar: Blanco
                    .padding()
                    .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                    .cornerRadius(25) // Forma ovalada
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                )
            }
            .padding()
            .background(Color.white.edgesIgnoringSafeArea(.all)) // Color de Fondo de la Vista Principal: Blanco
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
