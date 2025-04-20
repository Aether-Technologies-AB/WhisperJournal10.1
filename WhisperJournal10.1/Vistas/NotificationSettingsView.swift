//
//  NotificationSettingsView.swift
//  WhisperJournal10.1
//
//  Created by andree on 18/04/25.
//

import Foundation
import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled_preference")
    @State private var notificationFrequency = UserDefaults.standard.integer(forKey: "notification_frequency_preference") == 0 ? 7 : UserDefaults.standard.integer(forKey: "notification_frequency_preference")
    @State private var timeUnit = UserDefaults.standard.string(forKey: "notification_time_unit_preference") ?? "days" // "minutes", "hours", "days"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("reminders_section", comment: "Reminders section title"))) {
                    Toggle(NSLocalizedString("enable_reminders", comment: "Enable reminders toggle"), isOn: $isNotificationsEnabled)
                    
                    if isNotificationsEnabled {
                        // Selector de unidad de tiempo
                        Picker(NSLocalizedString("time_unit", comment: "Time unit selector"), selection: $timeUnit) {
                            Text(NSLocalizedString("minutes", comment: "Minutes")).tag("minutes")
                            Text(NSLocalizedString("hours", comment: "Hours")).tag("hours")
                            Text(NSLocalizedString("days", comment: "Days")).tag("days")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                        
                        // Límites dinámicos según la unidad de tiempo
                        let maxValue: Int = {
                            switch timeUnit {
                            case "minutes": return 59
                            case "hours": return 23
                            default: return 30 // días
                            }
                        }()
                        
                        Stepper(value: $notificationFrequency, in: 1...maxValue) {
                            Text(getFrequencyText())
                        }
                        
                        Button(action: {
                            scheduleNotifications()
                        }) {
                            Text(NSLocalizedString("save_settings", comment: "Save settings button"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.vertical)
                    }
                }
                
                Section(header: Text(NSLocalizedString("information_section", comment: "Information section title"))) {
                    Text(NSLocalizedString("reminders_info", comment: "Reminders information text"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationBarTitle(NSLocalizedString("reminders_settings_title", comment: "Reminders settings title"), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("close_button", comment: "Close button")) {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text(NSLocalizedString("reminders_alert_title", comment: "Reminders alert title")),
                    message: Text(alertMessage),
                    dismissButton: .default(Text(NSLocalizedString("ok_button", comment: "OK button")))
                )
            }
        }
    }
    
    // Obtener el texto de frecuencia según la unidad seleccionada
    private func getFrequencyText() -> String {
        let key: String
        switch timeUnit {
        case "minutes":
            key = "frequency_minutes"
        case "hours":
            key = "frequency_hours"
        default:
            key = "frequency_days"
        }
        return String(format: NSLocalizedString(key, comment: "Frequency text"), notificationFrequency)
    }
    
    private func scheduleNotifications() {
        // Guardar preferencias en UserDefaults
        UserDefaults.standard.set(isNotificationsEnabled, forKey: "notifications_enabled_preference")
        UserDefaults.standard.set(notificationFrequency, forKey: "notification_frequency_preference")
        UserDefaults.standard.set(timeUnit, forKey: "notification_time_unit_preference")
        
        if isNotificationsEnabled {
            // Convertir a segundos según la unidad
            var intervalInSeconds: TimeInterval = 0
            switch timeUnit {
            case "minutes":
                intervalInSeconds = TimeInterval(notificationFrequency * 60)
            case "hours":
                intervalInSeconds = TimeInterval(notificationFrequency * 60 * 60)
            default: // días
                intervalInSeconds = TimeInterval(notificationFrequency * 24 * 60 * 60)
            }
            
            NotificationService.shared.scheduleCustomFrequencyMemories(intervalInSeconds: intervalInSeconds)
            
            // Mensaje localizado según la unidad
            let formatKey = "recordatorios_configurados_" + timeUnit
            alertMessage = String(format: NSLocalizedString(formatKey, comment: "Reminders configured message"), notificationFrequency)
        } else {
            NotificationService.shared.cancelAllNotifications()
            alertMessage = NSLocalizedString("recordatorios_desactivados", comment: "Reminders deactivated message")
        }
        
        showingAlert = true
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}
