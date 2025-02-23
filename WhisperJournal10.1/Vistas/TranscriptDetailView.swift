//
//  TranscriptDetailView.swift
//  WhisperJournal10.1
//
//  Created by andree on 15/12/24.
//

import Foundation
import SwiftUI

struct TranscriptDetailView: View {
    let transcription: Transcription // Asegúrate de que este tipo tenga el campo de imagen

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transcription:")
                .font(.title2)
            Text(transcription.text)
                .padding()
            
            Text("Date:")
                .font(.headline)
            Text(transcription.date, style: .date)
                .foregroundColor(.gray)
            
            Text("Tags:")
                .font(.headline)
            Text(transcription.tags)
                .padding()
            
            // Mostrar la imagen asociada
            if let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty {
                ForEach(imagePaths, id: \.self) { imagePath in
                    if let image = PersistenceController.shared.loadImage(filename: imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200) // Ajusta el tamaño según sea necesario
                            .clipped()
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Details")
    }
}
