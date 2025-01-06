//
//  WhisperJournal10_1App.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import FirebaseCore

@main
struct WhisperJournal10_1App: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    init() {
        FirebaseApp.configure()
        
        // Limpiar cualquier dato persistente en UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")

        // Asegúrate de que isAuthenticated esté configurado en false por defecto
        if UserDefaults.standard.object(forKey: "isAuthenticated") == nil {
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
    }

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView() // Vista de grabación de audio
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
