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
            fatalError(NSLocalizedString("mic_access_error", comment: "Error message when microphone access fails"))
        }
        mic = input
        // No configurar la salida del motor de audio para evitar la retroalimentación
        // engine.output = Mixer(input)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text(NSLocalizedString("app_title", comment: "App title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black) // Color del Texto del Título: Negro
                    .padding()

                if isAuthenticated {
                    VStack {
                        Menu {
                            Button(NSLocalizedString("spanish", comment: "Spanish")) { selectedLanguage = "es-ES" }
                            Button(NSLocalizedString("english", comment: "English")) { selectedLanguage = "en-US" }
                            Button(NSLocalizedString("swedish", comment: "Swedish")) { selectedLanguage = "sv-SE" }
                        } label: {
                            Text("\(NSLocalizedString("select_language", comment: "Select Language")): \(selectedLanguage)")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.1))
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
                                Text(isRecording ? NSLocalizedString("stop_button", comment: "Stop button") : NSLocalizedString("record_button", comment: "Record button"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                        }
                        .padding(.top, 20)

                        // Mostrar la transcripción
                        if !recordedText.isEmpty {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("transcription_label", comment: "Transcription label"))
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
                        TextField(NSLocalizedString("enter_tags", comment: "Enter tags placeholder"), text: $tags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color(.systemGray6)) // Gris claro (systemGray6)
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Gris con opacidad del 20%

                        // Botón para guardar la transcripción
                        Button(action: saveTranscription) {
                            Text(NSLocalizedString("save_transcription", comment: "Save Transcription button"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                                .font(.headline)
                        }
                        .padding(.top, 10)

                        // Botón para ver transcripciones guardadas
                        NavigationLink(destination: TranscriptionListView()) {
                            Text(NSLocalizedString("view_saved_transcriptions", comment: "View Saved Transcriptions button"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                                .font(.headline)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    LoginView(isAuthenticated: $isAuthenticated)
                }

                Spacer()

                // Botón para cerrar sesión
                if isAuthenticated {
                    Button(action: {
                        WhisperJournal10_1App.logout()
                        isAuthenticated = false
                    }) {
                        Text(NSLocalizedString("logout_button", comment: "Logout button"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                            .font(.headline)
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(Color.white.edgesIgnoringSafeArea(.all)) // Color de Fondo de la Vista Principal: Blanco
            .navigationTitle(NSLocalizedString("home_title", comment: "Home title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
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
        // Detener la salida del motor de audio para evitar la retroalimentación
        engine.stop()
    }

    // Detener grabación
    func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
        // Reiniciar el motor de audio si es necesario
        do {
            try engine.start()
        } catch {
            print("Error al iniciar el motor de audio: \(error.localizedDescription)")
        }
    }

    // Guardar transcripción en Firebase
    func saveTranscription() {
        guard !recordedText.isEmpty else {
            print(NSLocalizedString("no_transcription_to_save", comment: "No transcription to save message"))
            return
        }
        
        guard let username = Auth.auth().currentUser?.email else {
            print(NSLocalizedString("no_user_logged_in", comment: "No user logged in message"))
            return
        }

        FirestoreService.shared.saveTranscription(
            username: username,
            text: recordedText,
            date: transcriptionDate,
            tags: tags
        ) { error in
            if let error = error {
                print("\(NSLocalizedString("error_saving_transcription", comment: "Error saving transcription message")): \(error.localizedDescription)")
            } else {
                print(NSLocalizedString("transcription_saved_successfully", comment: "Transcription saved successfully message"))
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
            print("\(NSLocalizedString("error_starting_audio_engine", comment: "Error starting audio engine message")): \(error.localizedDescription)")
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
