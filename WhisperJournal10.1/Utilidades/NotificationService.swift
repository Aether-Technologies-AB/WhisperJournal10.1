//
//  NotificationService.swift
//  WhisperJournal10.1
//
//  Created by andree on 18/04/25.
//

import Foundation
import UserNotifications
import Firebase

class NotificationService {
    static let shared = NotificationService()
    
    private init() {
        // No solicitar autorización automáticamente en init
        // Se hará cuando se llame a scheduleWeeklyMemories o scheduleCustomFrequencyMemories
    }
    
    // Solicitar permiso para enviar notificaciones
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print(NSLocalizedString("notifications_auth_granted", comment: "Notifications authorization granted"))
            } else if let error = error {
                print(String(format: NSLocalizedString("notifications_auth_error", comment: "Error requesting notification authorization"), error.localizedDescription))
            }
        }
    }
    
    // Programar notificaciones semanales de recuerdos
    func scheduleWeeklyMemories() {
        // Primero solicitar autorización
        requestAuthorization()
        
        // Verificar que Firebase esté inicializado
        guard Firebase.Auth.auth().app != nil else {
            print(NSLocalizedString("firebase_not_initialized", comment: "Firebase not properly initialized"))
            return
        }
        
        guard let username = Auth.auth().currentUser?.email else {
            print(NSLocalizedString("user_not_authenticated", comment: "User not authenticated message"))
            return
        }
        
        // Obtener transcripciones del usuario
        FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
            guard let transcriptions = transcriptions, error == nil else {
                print(String(format: NSLocalizedString("fetch_transcriptions_error", comment: "Error fetching transcriptions"), error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "Unknown error")))
                return
            }
            
            // Filtrar transcripciones importantes (con etiquetas específicas o más antiguas)
            let importantTranscriptions = self.filterImportantTranscriptions(transcriptions)
            
            // Programar notificaciones para cada transcripción importante
            for (index, transcription) in importantTranscriptions.enumerated() {
                self.scheduleNotification(
                    for: transcription,
                    dayOffset: index * 2, // Espaciar las notificaciones cada 2 días
                    identifier: "memory-\(transcription.id ?? UUID().uuidString)"
                )
            }
        }
    }
    
    // Filtrar transcripciones importantes
    private func filterImportantTranscriptions(_ transcriptions: [Transcription]) -> [Transcription] {
        // Priorizar transcripciones con etiquetas importantes
        let importantTags = ["importante", "memorable", "especial", "cumpleaños", "aniversario", "logro"]
        
        let taggedTranscriptions = transcriptions.filter { transcription in
            return !Set(transcription.tags.map { $0.lowercased() }).isDisjoint(with: Set(importantTags))
        }
        
        // Si no hay suficientes con etiquetas, agregar algunas basadas en la fecha (más antiguas)
        var result = Array(taggedTranscriptions)
        
        if result.count < 5 {
            let oldTranscriptions = transcriptions
                .filter { !result.contains($0) }
                .sorted { $0.date < $1.date }
                .prefix(5 - result.count)
            
            result.append(contentsOf: oldTranscriptions)
        }
        
        return result.shuffled().prefix(5).sorted { $0.date > $1.date }
    }
    
    // Programar una notificación para una transcripción específica con offset en días
    private func scheduleNotification(for transcription: Transcription, dayOffset: Int, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("memory_notification_title", comment: "Memory notification title")
        
        // Crear un extracto del texto (primeras 100 caracteres)
        let textPreview = String(transcription.text.prefix(100))
        content.body = "\(textPreview)..."
        
        content.sound = UNNotificationSound.default
        
        // Crear un trigger para la fecha deseada (próximo domingo + offset)
        var dateComponents = Calendar.current.dateComponents([.weekday], from: Date())
        let currentWeekday = dateComponents.weekday ?? 1
        let daysUntilSunday = (8 - currentWeekday) % 7 // Días hasta el próximo domingo
        
        let triggerDate = Calendar.current.date(byAdding: .day, value: daysUntilSunday + dayOffset, to: Date())!
        dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 10 // Notificar a las 10 AM
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Crear la solicitud de notificación
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Agregar la solicitud al centro de notificaciones
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(String(format: NSLocalizedString("schedule_notification_error", comment: "Error scheduling notification"), error.localizedDescription))
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let date = Calendar.current.date(from: dateComponents) ?? Date()
                let formattedDate = dateFormatter.string(from: date)
                print(String(format: NSLocalizedString("notification_scheduled_success", comment: "Notification scheduled successfully"), formattedDate))
            }
        }
    }
    
    // Cancelar todas las notificaciones programadas
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Programar notificaciones con frecuencia personalizada (en días o segundos)
    func scheduleCustomFrequencyMemories(frequency: Int? = nil, intervalInSeconds: TimeInterval? = nil) {
        // Cancelar notificaciones existentes
        cancelAllNotifications()
        
        // Determinar el intervalo en segundos
        let interval: TimeInterval
        if let intervalInSeconds = intervalInSeconds {
            interval = intervalInSeconds
        } else if let frequency = frequency {
            // Convertir días a segundos
            interval = TimeInterval(frequency * 24 * 60 * 60)
        } else {
            // Valor por defecto: 7 días
            interval = 7 * 24 * 60 * 60
        }
        
        // Primero solicitar autorización
        requestAuthorization()
        
        // Verificar que Firebase esté inicializado
        guard Firebase.Auth.auth().app != nil else {
            print(NSLocalizedString("firebase_not_initialized", comment: "Firebase not properly initialized"))
            return
        }
        
        guard let username = Auth.auth().currentUser?.email else {
            print(NSLocalizedString("user_not_authenticated", comment: "User not authenticated message"))
            return
        }
        
        FirestoreService.shared.fetchTranscriptions(username: username) { transcriptions, error in
            guard let transcriptions = transcriptions, error == nil else {
                print(String(format: NSLocalizedString("fetch_transcriptions_error", comment: "Error fetching transcriptions"), error?.localizedDescription ?? NSLocalizedString("unknown_error", comment: "Unknown error")))
                return
            }
            
            let importantTranscriptions = self.filterImportantTranscriptions(transcriptions)
            
            for (index, transcription) in importantTranscriptions.enumerated() {
                // Calcular el offset en segundos (interval * index) para espaciar las notificaciones
                let secondsOffset = interval * Double(index)
                let identifier = "custom-memory-\(transcription.id ?? UUID().uuidString)"
                self.scheduleNotificationWithInterval(for: transcription, secondsOffset: secondsOffset, identifier: identifier)
            }
        }
    }
    
    // Programar notificación con intervalo en segundos
    private func scheduleNotificationWithInterval(for transcription: Transcription, secondsOffset: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("memory_notification_title", comment: "Memory notification title")
        
        let textPreview = String(transcription.text.prefix(100))
        content.body = "\(textPreview)..."
        
        content.sound = UNNotificationSound.default
        
        // Crear un trigger basado en el intervalo de tiempo en segundos
        // Añadir datos para poder abrir la transcripción al tocar la notificación
        content.userInfo = ["transcriptionId": transcription.id ?? ""]
        
        // Crear un trigger con el intervalo especificado
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsOffset > 0 ? secondsOffset : 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(String(format: NSLocalizedString("custom_notification_error", comment: "Error scheduling custom notification"), error.localizedDescription))
            }
        }
    }
}
