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
            Form {
                Section(header: Text(NSLocalizedString("edit_transcription_text", comment: "Text section header"))) {
                    TextEditor(text: $transcription.text)
                        .frame(minHeight: 200)
                }
                
                Section(header: Text(NSLocalizedString("edit_transcription_tags", comment: "Tags section header"))) {
                    TextField(NSLocalizedString("enter_tags", comment: "Enter tags placeholder"), text: $transcription.tags)
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
                },
                trailing: Button(NSLocalizedString("edit_transcription_save", comment: "Save button")) {
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
