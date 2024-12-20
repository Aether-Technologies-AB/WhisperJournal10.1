//
//  AudioRecorder.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//


import AVFoundation
import Speech

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession!
    private var audioFileURL: URL!
    
    var transcriptionHandler: ((String) -> Void)?
    private var selectedLanguageCode: String = "es-ES" // Idioma por defecto
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? audioSession.setActive(true)
    }
    
    func setLanguageCode(_ languageCode: String) {
        self.selectedLanguageCode = languageCode
    }
    
    func startRecording(completion: @escaping (String) -> Void) {
        transcriptionHandler = completion
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        audioFileURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        transcribeAudio()
    }
    
    private func transcribeAudio() {
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: selectedLanguageCode)) else {
                print("Speech recognizer not available for language: \(selectedLanguageCode)")
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
            
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("Error transcribing audio: \(error)")
                    return
                }
            
            if let result = result {
                let currentTime = self.getCurrentTime()
                let transcriptionWithTime = "\(currentTime): \(result.bestTranscription.formattedString)"
                self.transcriptionHandler?(transcriptionWithTime)
            }
        }
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // Formato de hora
        return formatter.string(from: Date())
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
