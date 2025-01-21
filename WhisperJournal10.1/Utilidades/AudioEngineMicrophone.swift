//
//  AudioEngineMicrophone.swift
//  WhisperJournal10.1
//
//  Created by andree on 15/12/24.
//



import Foundation
import AudioKit

class AudioEngineMicrophone: ObservableObject {
    let audioEngine = AudioEngine()
    let audioInput: AudioEngine.InputNode
    let mixer = Mixer()

    init() {
        guard let input = audioEngine.input else {
            fatalError("No se pudo acceder al micrófono.")
        }
        self.audioInput = input
        
        // Configure audio routing
        mixer.addInput(audioInput)
        audioEngine.output = mixer
    }

    func start() {
        do {
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Error al iniciar el motor de audio: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioEngine.stop()
        print("Audio engine stopped successfully")
    }
}
