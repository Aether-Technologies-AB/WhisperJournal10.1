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

// Estructura para manejar la respuesta de Whisper
struct WhisperResponse: Codable {
    let text: String
}

class WhisperService {
    static let shared = WhisperService()
    private init() {}
    
    func transcribeAudio(at url: URL, language: String, completion: @escaping (String?) -> Void) {
        // Convertir el código de idioma al formato ISO-639-1 requerido por la API
        let isoLanguage = convertToISO639_1(language)
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
        
        // Obtener la API key desde APIKeys
        let apiKey = APIKeys.openAI
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
            body.append(isoLanguage.data(using: .utf8)!)
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
                let decoder = JSONDecoder()
                let response = try decoder.decode(WhisperResponse.self, from: data)
                completion(response.text)
            } catch {
                print("Error al decodificar JSON: \(error)")
                // Imprimir la respuesta para debug
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("Respuesta recibida: \(responseStr)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // Convierte códigos de idioma al formato ISO-639-1 requerido por la API de Whisper
    private func convertToISO639_1(_ language: String) -> String {
        // Si está vacío, devolvemos vacío para que la API detecte automáticamente
        if language.isEmpty {
            return ""
        }
        
        // Convertir a minúsculas y obtener solo la primera parte (antes del guión si existe)
        let lowercased = language.lowercased()
        let primaryCode = lowercased.split(separator: "-").first ?? ""
        
        // Mapeo de códigos de idioma a ISO-639-1
        let languageMap: [String: String] = [
            "español": "es",
            "spanish": "es",
            "inglés": "en",
            "english": "en",
            "sueco": "sv",
            "swedish": "sv",
            "es": "es",
            "en": "en",
            "sv": "sv"
        ]
        
        // Buscar en el mapa o usar la primera parte del código
        if let mappedCode = languageMap[String(primaryCode)] {
            return mappedCode
        } else if let mappedCode = languageMap[lowercased] {
            return mappedCode
        }
        
        // Si no hay coincidencia en el mapa, devolvemos los primeros dos caracteres
        // o vacío si es demasiado corto
        if primaryCode.count >= 2 {
            return String(primaryCode.prefix(2))
        }
        
        // Si todo falla, devolvemos vacío para detección automática
        return ""
    }
}
