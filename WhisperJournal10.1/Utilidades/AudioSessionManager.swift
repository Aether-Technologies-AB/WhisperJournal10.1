//
//  AudioSessionManager.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//

import Foundation
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}
    
    var audioRecorder: AVAudioRecorder?
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Error al configurar la sesión de audio: \(error)")
        }
    }
    
    func startRecording(to url: URL) {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Error al iniciar la grabación: \(error)")
        }
    }
    
    func stopRecording() {
            if let recorder = audioRecorder, recorder.isRecording {
                recorder.stop()
            } else {
                print("No hay grabación en curso para detener.")
            }
        }
    }
