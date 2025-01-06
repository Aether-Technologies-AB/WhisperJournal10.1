//
//  RecordingView.swif.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import AVFoundation
import CoreData

struct RecordingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("username") private var username: String = ""

    @State private var isRecording = false
    @State private var recordedText = ""
    @State private var transcriptionDate = Date()
    @State private var tags = ""
    @State private var selectedLanguage = "es-ES" // Idioma por defecto
    @State private var audioURL: URL?
    @State private var transcriptions: [Transcription] = []

    let audioRecorder = AudioRecorder()

    var body: some View {
        NavigationView {
            VStack {
                Text("Record New Transcription")
                    .font(.title2)
                    .padding()

                Menu {
                    Button("Español") { selectedLanguage = "es-ES" }
                    Button("Inglés") { selectedLanguage = "en-US" }
                    Button("Sueco") { selectedLanguage = "sv-SE" }
                    // Agrega más idiomas según sea necesario
                } label: {
                    Text("Selecciona el idioma: \(selectedLanguage)")
                        .padding()
                        .background(Color.gray.opacity(0.2))
                }

                Button(isRecording ? "Detener Grabación" : "Iniciar Grabación") {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }
                .padding()
                
                if !recordedText.isEmpty {
                    Text("Transcripción:")
                        .font(.headline)
                        .padding(.top)
                    Text(recordedText)
                        .padding()
                }

                List(transcriptions) { transcription in
                    VStack(alignment: .leading) {
                        Text(transcription.text)
                        Text(transcription.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .navigationBarTitle("Whisper Journal")
            .onAppear {
                fetchTranscriptions()
            }
        }
    }

    private func startRecording() {
        audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
        if let url = audioURL {
            AudioSessionManager.shared.startRecording(to: url)
            isRecording = true
        }
    }

    private func stopRecording() {
        AudioSessionManager.shared.stopRecording()
        isRecording = false
        if let url = audioURL {
            transcribeAudio(at: url)
        }
    }

    private func transcribeAudio(at url: URL) {
        WhisperService.shared.transcribeAudio(at: url, language: selectedLanguage) { transcription in
            if let transcription = transcription {
                recordedText = transcription
                saveTranscription(text: transcription)
            }
        }
    }

    private func saveTranscription(text: String) {
        FirestoreService.shared.saveTranscription(username: username, text: text, date: transcriptionDate, tags: tags) { error in
            if let error = error {
                print("Error al guardar la transcripción: \(error.localizedDescription)")
            } else {
                fetchTranscriptions()
            }
        }
    }

    private func fetchTranscriptions() {
        FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
            if let transcriptions = transcriptions {
                self.transcriptions = transcriptions
            } else {
                print("Error al obtener las transcripciones: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }
}
