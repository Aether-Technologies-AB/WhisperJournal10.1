//
//  WisperService.swift
//  WhisperJournal10.1
//
//  Created by andree on 26/12/24.
//

//
//  WisperService.swift
//  WhisperJournal10.1
//
//  Created by andree on 26/12/24.
//

import Foundation

class WhisperService {
    static let shared = WhisperService()
    private init() {}
    
    func transcribeAudio(at url: URL, language: String, completion: @escaping (String?) -> Void) {
        // La API de OpenAI espera el archivo de audio, no una URL
        guard let audioData = try? Data(contentsOf: url) else {
            print("Error al leer el archivo de audio")
            completion(nil)
            return
        }
        
        guard let apiUrl = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            completion(nil)
            return
        }
        
        // Crear el cuerpo multipart
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Obtener la API key de las variables de entorno o configuración
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Agregar el archivo de audio
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Agregar el modelo (whisper-1)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Agregar el idioma si está especificado
        if !language.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append(language.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Finalizar el cuerpo multipart
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
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
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let text = json["text"] as? String {
                    completion(text)
                } else {
                    print("Error al parsear la respuesta")
                    completion(nil)
                }
            } catch {
                print("Error al decodificar JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}
