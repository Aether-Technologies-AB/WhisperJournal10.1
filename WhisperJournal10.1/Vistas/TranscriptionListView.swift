//
//  TranscriptionListView.swift
//  WhisperJournal10.1
//
//  Created by andree on 15/12/24.
//

import Foundation
import SwiftUI
import CoreData

struct TranscriptionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transcript.date, ascending: false)],
        animation: .default)
    private var transcripts: FetchedResults<Transcript>
    
    var body: some View {
        List {
            ForEach(transcripts) { transcript in
                NavigationLink(destination: TranscriptDetailView(transcript: transcript)) {
                    VStack(alignment: .leading) {
                        Text(transcript.text ?? "No Text")
                            .font(.headline)
                        Text(transcript.date ?? Date(), style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onDelete(perform: deleteTranscription)
        }
        .navigationTitle("Saved Transcriptions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func deleteTranscription(offsets: IndexSet) {
        withAnimation {
            offsets.map { transcripts[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting transcription: \(error.localizedDescription)")
            }
        }
    }
}

