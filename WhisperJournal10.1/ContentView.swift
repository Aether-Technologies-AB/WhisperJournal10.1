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
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text(NSLocalizedString("app_title", comment: "App title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
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
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding()

                        if isRecording {
                            NodeOutputView(mic)
                                .frame(height: 150)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                                .padding()
                        }

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
                            .background(LinearGradient(colors: isRecording ? [Color.red, Color.pink] : [Color.green, Color.teal], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 20)

                        if !recordedText.isEmpty {
                            VStack(alignment: .leading) {
                                Text(NSLocalizedString("transcription_label", comment: "Transcription label"))
                                    .font(.headline)
                                    .padding(.top, 20)

                                Text(recordedText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                            .padding()
                        }

                        TextField(NSLocalizedString("enter_tags", comment: "Enter tags placeholder"), text: $tags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 4)

                        Button(action: saveTranscription) {
                            Text(NSLocalizedString("save_transcription", comment: "Save Transcription button"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                                .font(.headline)
                        }
                        .padding(.top, 10)

                        NavigationLink(destination: TranscriptionListView()) {
                            Text(NSLocalizedString("view_saved_transcriptions", comment: "View Saved Transcriptions button"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [Color.cyan, Color.indigo], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                                .font(.headline)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    LoginView(isAuthenticated: $isAuthenticated)
                }

                Spacer()

                if isAuthenticated {
                    Button(action: {
                        WhisperJournal10_1App.logout()
                        isAuthenticated = false
                    }) {
                        Text(NSLocalizedString("logout_button", comment: "Logout button"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color.gray, Color.black], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                            .font(.headline)
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(Color.white.edgesIgnoringSafeArea(.all))
            .navigationTitle(NSLocalizedString("home_title", comment: "Home title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                startAudioEngine()
            }
            .onDisappear {
                stopAudioEngine()
            }
        }
    }

    func startRecording() {
        audioRecorder.setLanguageCode(selectedLanguage)
        audioRecorder.startRecording { transcription in
            self.recordedText = transcription
            self.transcriptionDate = Date()
        }
        isRecording = true
        engine.stop()
    }

    func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
        do {
            try engine.start()
        } catch {
            print("Error al iniciar el motor de audio: \(error.localizedDescription)")
        }
    }

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

    func resetFields() {
        recordedText = ""
        tags = ""
    }

    func startAudioEngine() {
        do {
            try engine.start()
        } catch {
            print("\(NSLocalizedString("error_starting_audio_engine", comment: "Error starting audio engine message")): \(error.localizedDescription)")
        }
    }

    func stopAudioEngine() {
        engine.stop()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
