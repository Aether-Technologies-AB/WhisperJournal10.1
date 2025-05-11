//
//  MemoriesService.swift
//  WhisperJournal10.1
//
//  Created by andree on 25/04/25.
//

import Foundation
import UIKit
import UserNotifications
import NaturalLanguage
import Firebase
import FirebaseAuth

/// Servicio para crear y gestionar recuerdos inteligentes similar a Apple Photos
class MemoriesService {
    static let shared = MemoriesService()
    
    private let nlTagger = NLTagger(tagSchemes: [.nameType, .lemma])
    private let dateDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    
    // Categorías para clasificación de transcripciones
    enum TranscriptionCategory: String {
        case personal, work, family, travel, achievement, health, other
    }
    
    // Estructura para almacenar insights de una transcripción
    struct TranscriptionInsights {
        var entities: [String: String] // [nombre: tipo]
        var dates: [Date]
        var category: TranscriptionCategory
        var emotionalTone: String // positive, negative, neutral
        var keywords: [String]
    }
    
    private init() {}
    
    // MARK: - Análisis de Contenido
    
    /// Analiza el contenido de una transcripción para extraer información relevante
    func analyzeTranscriptionContent(_ transcription: Transcription) -> TranscriptionInsights {
        let text = transcription.text
        
        // Configurar el tagger
        nlTagger.string = text
        
        // Extraer entidades (personas, lugares)
        var entities: [String: String] = [:]
        nlTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag, tag != .other {
                let entity = String(text[range])
                entities[entity] = tag.rawValue
            }
            return true
        }
        
        // Detectar fechas en el texto
        var dates: [Date] = []
        if let dateDetector = dateDetector {
            let matches = dateDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let date = match.date {
                    dates.append(date)
                }
            }
        }
        
        // Determinar categoría basada en palabras clave y etiquetas
        let category = determineCategory(text: text, tags: transcription.tags)
        
        // Analizar tono emocional (simplificado)
        let emotionalTone = analyzeEmotionalTone(text: text)
        
        // Extraer palabras clave
        let keywords = extractKeywords(from: text)
        
        return TranscriptionInsights(
            entities: entities,
            dates: dates,
            category: category,
            emotionalTone: emotionalTone,
            keywords: keywords
        )
    }
    
    /// Determina la categoría de una transcripción basada en su contenido y etiquetas
    private func determineCategory(text: String, tags: String) -> TranscriptionCategory {
        let lowercasedText = text.lowercased()
        // Dividir la cadena de etiquetas en un array, eliminando espacios en blanco
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        // Palabras clave para cada categoría
        let personalKeywords = ["yo", "mi", "sentimiento", "emoción", "personal", "diario"]
        let workKeywords = ["trabajo", "proyecto", "reunión", "cliente", "jefe", "oficina"]
        let familyKeywords = ["familia", "hijo", "hija", "padre", "madre", "hermano", "hermana"]
        let travelKeywords = ["viaje", "vacaciones", "hotel", "vuelo", "turismo", "visita"]
        let achievementKeywords = ["logro", "éxito", "conseguir", "completar", "ganar", "premio"]
        let healthKeywords = ["salud", "médico", "ejercicio", "dieta", "enfermedad", "bienestar"]
        
        // Verificar coincidencias en etiquetas primero (mayor prioridad)
        for tag in tagArray {
            if personalKeywords.contains(tag) { return .personal }
            if workKeywords.contains(tag) { return .work }
            if familyKeywords.contains(tag) { return .family }
            if travelKeywords.contains(tag) { return .travel }
            if achievementKeywords.contains(tag) { return .achievement }
            if healthKeywords.contains(tag) { return .health }
        }
        
        // Verificar coincidencias en el texto
        var scores: [TranscriptionCategory: Int] = [.personal: 0, .work: 0, .family: 0, .travel: 0, .achievement: 0, .health: 0]
        
        for keyword in personalKeywords where lowercasedText.contains(keyword) { scores[.personal]! += 1 }
        for keyword in workKeywords where lowercasedText.contains(keyword) { scores[.work]! += 1 }
        for keyword in familyKeywords where lowercasedText.contains(keyword) { scores[.family]! += 1 }
        for keyword in travelKeywords where lowercasedText.contains(keyword) { scores[.travel]! += 1 }
        for keyword in achievementKeywords where lowercasedText.contains(keyword) { scores[.achievement]! += 1 }
        for keyword in healthKeywords where lowercasedText.contains(keyword) { scores[.health]! += 1 }
        
        // Determinar la categoría con mayor puntuación
        if let maxCategory = scores.max(by: { $0.value < $1.value }), maxCategory.value > 0 {
            return maxCategory.key
        }
        
        return .other
    }
    
    /// Analiza el tono emocional del texto
    private func analyzeEmotionalTone(text: String) -> String {
        let lowercasedText = text.lowercased()
        
        let positiveWords = ["feliz", "contento", "alegre", "éxito", "logro", "amor", "satisfecho", "agradecido"]
        let negativeWords = ["triste", "enojado", "frustrado", "preocupado", "miedo", "ansiedad", "problema"]
        
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords where lowercasedText.contains(word) { positiveCount += 1 }
        for word in negativeWords where lowercasedText.contains(word) { negativeCount += 1 }
        
        if positiveCount > negativeCount { return "positive" }
        if negativeCount > positiveCount { return "negative" }
        return "neutral"
    }
    
    /// Extrae palabras clave del texto
    private func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        
        nlTagger.string = text
        nlTagger.setLanguage(.spanish, range: text.startIndex..<text.endIndex)
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        nlTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            if let lemma = tag?.rawValue {
                let word = String(text[range])
                // Filtrar palabras comunes y cortas
                if word.count > 3 && !["para", "como", "esto", "esta", "pero", "cuando", "porque"].contains(word.lowercased()) {
                    keywords.append(lemma)
                }
            }
            return true
        }
        
        // Eliminar duplicados y limitar a 10 palabras clave
        return Array(Set(keywords)).prefix(10).map { $0 }
    }
    
    // MARK: - Gestión de Recuerdos
    
    /// Programa notificaciones inteligentes basadas en el análisis de contenido
    func scheduleIntelligentMemories() {
        guard let username = Auth.auth().currentUser?.email else { return }
        
        // Cancelar notificaciones existentes
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Obtener todas las transcripciones
        FirestoreService.shared.fetchTranscriptions(username: username) { [weak self] transcriptions, error in
            guard let self = self, let transcriptions = transcriptions, error == nil else { return }
            
            // Agrupar transcripciones por categoría
            let categorizedTranscriptions = self.categorizeTranscriptions(transcriptions)
            
            // Programar diferentes tipos de recuerdos
            self.scheduleAnniversaryMemories(transcriptions: transcriptions)
            self.scheduleThematicMemories(categorizedTranscriptions: categorizedTranscriptions)
            self.scheduleWeeklyDigests(transcriptions: transcriptions)
        }
    }
    
    /// Agrupa transcripciones por categoría
    private func categorizeTranscriptions(_ transcriptions: [Transcription]) -> [TranscriptionCategory: [Transcription]] {
        var result: [TranscriptionCategory: [Transcription]] = [:]
        
        for transcription in transcriptions {
            let insights = analyzeTranscriptionContent(transcription)
            let category = insights.category
            
            if result[category] == nil {
                result[category] = []
            }
            result[category]?.append(transcription)
        }
        
        return result
    }
    
    /// Programa recuerdos basados en aniversarios
    private func scheduleAnniversaryMemories(transcriptions: [Transcription]) {
        let calendar = Calendar.current
        let now = Date()
        
        for transcription in transcriptions {
            // Verificar si hay un aniversario próximo (1 año, 2 años, etc.)
            let transcriptionDate = transcription.date
            let components = calendar.dateComponents([.year, .month, .day], from: transcriptionDate, to: now)
            
            if let years = components.year, years > 0 && components.month == 0 && abs(components.day ?? 0) <= 7 {
                // Es un aniversario próximo (±7 días)
                let title = String(format: NSLocalizedString("anniversary_memory_title", comment: ""), years)
                scheduleRichNotification(for: transcription, title: title, delay: Double(arc4random_uniform(7)) * 86400)
            }
        }
    }
    
    /// Programa recuerdos temáticos basados en categorías
    private func scheduleThematicMemories(categorizedTranscriptions: [TranscriptionCategory: [Transcription]]) {
        for (category, transcriptions) in categorizedTranscriptions {
            guard !transcriptions.isEmpty else { continue }
            
            // Seleccionar hasta 3 transcripciones por categoría
            let selectedTranscriptions = transcriptions.sorted { $0.date > $1.date }.prefix(3)
            
            // Título basado en la categoría
            let title: String
            switch category {
            case .personal: title = NSLocalizedString("personal_memories_title", comment: "")
            case .work: title = NSLocalizedString("work_memories_title", comment: "")
            case .family: title = NSLocalizedString("family_memories_title", comment: "")
            case .travel: title = NSLocalizedString("travel_memories_title", comment: "")
            case .achievement: title = NSLocalizedString("achievement_memories_title", comment: "")
            case .health: title = NSLocalizedString("health_memories_title", comment: "")
            case .other: title = NSLocalizedString("memories_title", comment: "")
            }
            
            // Programar notificación para cada transcripción seleccionada con un retraso diferente
            for (index, transcription) in selectedTranscriptions.enumerated() {
                let delay = Double(index * 2 + 1) * 86400 // Cada 2 días
                scheduleRichNotification(for: transcription, title: title, delay: delay)
            }
        }
    }
    
    /// Programa resúmenes semanales
    private func scheduleWeeklyDigests(transcriptions: [Transcription]) {
        // Obtener transcripciones de la última semana
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentTranscriptions = transcriptions.filter { $0.date >= oneWeekAgo }
        guard !recentTranscriptions.isEmpty else { return }
        
        // Crear un resumen con hasta 5 transcripciones recientes
        let digestTranscriptions = recentTranscriptions.sorted { $0.date > $1.date }.prefix(5)
        
        // Programar para el próximo domingo a las 10 AM
        var dateComponents = calendar.dateComponents([.weekday], from: Date())
        let currentWeekday = dateComponents.weekday ?? 1
        let daysUntilSunday = (8 - currentWeekday) % 7 // Días hasta el próximo domingo
        
        let triggerDate = calendar.date(byAdding: .day, value: daysUntilSunday, to: Date())!
        dateComponents = calendar.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 10 // 10 AM
        
        // Crear contenido de notificación para el resumen
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("weekly_digest_title", comment: "")
        content.body = String(format: NSLocalizedString("weekly_digest_body", comment: ""), digestTranscriptions.count)
        content.sound = UNNotificationSound.default
        
        // Incluir IDs de todas las transcripciones en el resumen
        let transcriptionIds = digestTranscriptions.compactMap { $0.id }
        content.userInfo = ["digestIds": transcriptionIds]
        
        // Añadir imagen si está disponible
        if let firstTranscription = digestTranscriptions.first,
           let imagePath = firstTranscription.imageLocalPaths?.first,
           let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(imagePath) {
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                content.attachments = [attachment]
            } catch {
                print("Error creando attachment: \(error)")
            }
        }
        
        // Crear trigger y solicitud
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "weekly-digest", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error programando resumen semanal: \(error)")
            }
        }
    }
    
    /// Crea y programa una notificación rica para una transcripción
    private func scheduleRichNotification(for transcription: Transcription, title: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        
        // Crear un extracto del texto
        let textPreview = String(transcription.text.prefix(100))
        content.body = "\(textPreview)..."
        
        content.sound = UNNotificationSound.default
        content.userInfo = ["transcriptionId": transcription.id ?? ""]
        
        // Añadir imagen si está disponible
        if let imagePath = transcription.imageLocalPaths?.first,
           let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(imagePath) {
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
                content.attachments = [attachment]
            } catch {
                print("Error creando attachment: \(error)")
            }
        }
        
        // Crear trigger con el delay especificado
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay > 0 ? delay : 60, repeats: false)
        
        // Identificador único para la notificación
        let identifier = "memory-\(transcription.id ?? "")-\(Date().timeIntervalSince1970)"
        
        // Crear y programar la solicitud
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error programando notificación rica: \(error)")
            }
        }
    }
}
