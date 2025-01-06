//
//  WhisperJournal10_1App.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WhisperJournal10_1App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    init() {
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
