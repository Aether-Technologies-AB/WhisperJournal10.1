//
//  WisperService.swift
//  WhisperJournal10.1
//
//  Created by andree on 26/12/24.
//

import Foundation
import Foundation

class WhisperService {
    static let shared = WhisperService()
    private init() {}
    
    func transcribeAudio(at url: URL, completion: @escaping (String?) -> Void) {
        guard let apiUrl = URL(string: "https://api.whisper.ai/transcribe") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Reemplaza la clave API con una variable de entorno
        let apiKey = ProcessInfo.processInfo.environment[""] ?? ""
        
        let body: [String: Any] = [
            "audio_url": url.absoluteString,
            "language": "language",
            "api_key": apiKey
        ]
        
        // Convierte el cuerpo en JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error al convertir datos en JSON: \(error)")
            completion(nil)
            return
        }
        
        // Realiza la solicitud HTTP
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error en la solicitud HTTP: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No se recibieron datos")
                completion(nil)
                return
            }
            
            // Procesa la respuesta
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let transcription = jsonResponse["transcription"] as? String {
                    completion(transcription)
                } else {
                    print("Formato de respuesta inesperado")
                    completion(nil)
                }
            } catch {
                print("Error al procesar la respuesta: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
