//
//  RecordingViewModel.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//


import Foundation
import AVFoundation

class RecordingViewModel: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    @Published var transcription: String?
    
    // Configurar la sesión de audio
    func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.record, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Error configurando la sesión de audio: \(error)")
        }
    }
    
    // Iniciar grabación
    func startRecording() {
        let filename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Error al iniciar la grabación: \(error)")
        }
    }
    
    // Detener grabación
    func stopRecording() {
        audioRecorder?.stop()
        if let url = audioRecorder?.url {
            transcribeAudio(at: url, language: "es-ES") // Asegúrate de pasar el parámetro 'language'
        }
    }
    
    // Transcribir audio
    private func transcribeAudio(at url: URL, language: String) {
        WhisperService.shared.transcribeAudio(at: url, language: language) { transcription in
            if let transcription = transcription {
                DispatchQueue.main.async {
                    self.transcription = transcription
                }
            }
        }
    }
    
    // Obtener el directorio de documentos
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
