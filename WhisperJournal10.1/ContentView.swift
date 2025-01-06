//
//  ContentView.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import AVFoundation
import AudioKit
import AudioKitUI
import FirebaseAuth

struct ContentView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isRecording = false
    @State private var recordedText = ""
    @State private var transcriptionDate = Date()
    @State private var tags = ""
    @State private var selectedLanguage: String = "es-ES" // Idioma por defecto


    let audioRecorder = AudioRecorder()
    let engine = AudioEngine()
    let mic: AudioEngine.InputNode

    init() {
        // Configurar el nodo del micrófono
        guard let input = engine.input else {
            fatalError("No se pudo acceder al micrófono.")
        }
        mic = input
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Whisper Journal")
                    .font(.largeTitle)
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
                        .cornerRadius(8)
                }
                .padding()

                // Visualizador de ondas de audio
                if isRecording {
                    NodeOutputView(mic)
                        .frame(height: 150)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding()
                }

                // Botón para grabar
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title)
                        Text(isRecording ? "Detener" : "Grabar")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 20)

                // Mostrar la transcripción
                if !recordedText.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Transcripción:")
                            .font(.headline)
                            .padding(.top, 20)

                        Text(recordedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }

                // Campo de entrada para Tags
                TextField("Enter tags...", text: $tags)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Botón para guardar la transcripción
                Button(action: saveTranscription) {
                    Text("Guardar Transcripción")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.top, 10)

                // Botón para ver transcripciones guardadas
                NavigationLink(destination: TranscriptionListView()) {
                    Text("Ver Transcripciones Guardadas")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        WhisperJournal10_1App.logout()
                        isAuthenticated = false
                    }) {
                        Text("Cerrar Sesión")
                            .foregroundColor(.red)
                    }
                }
            }
            .onAppear {
                startAudioEngine()
            }
            .onDisappear {
                stopAudioEngine()
            }
        }
    }

    // Iniciar grabación
    func startRecording() {
        audioRecorder.setLanguageCode(selectedLanguage)
        audioRecorder.startRecording { transcription in
            self.recordedText = transcription
            self.transcriptionDate = Date()
            // Guarda la transcripción en Core Data o realiza otras acciones necesarias
        }
        isRecording = true
    }

    // Detener grabación
    func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
    }

    // Guardar transcripción en Firebase
    func saveTranscription() {
        guard !recordedText.isEmpty else {
            print("No transcription to save.")
            return
        }
        
        guard let username = Auth.auth().currentUser?.email else {
            print("No user logged in")
            return
        }

        FirestoreService.shared.saveTranscription(
            username: username,
            text: recordedText,
            date: transcriptionDate,
            tags: tags
        ) { error in
            if let error = error {
                print("Error saving transcription: \(error.localizedDescription)")
            } else {
                print("Transcription saved successfully!")
                resetFields()
            }
        }
    }

    // Reiniciar campos después de guardar
    func resetFields() {
        recordedText = ""
        tags = ""
    }

    // Iniciar el motor de audio
    func startAudioEngine() {
        do {
            try engine.start()
        } catch {
            print("Error al iniciar el motor de audio: \(error.localizedDescription)")
        }
    }

    // Detener el motor de audio
    func stopAudioEngine() {
        engine.stop()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
