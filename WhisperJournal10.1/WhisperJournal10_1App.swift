//
//  WhisperJournal10_1App.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import Firebase  // Añadir esta importación
import FirebaseCore
import FirebaseAuth
import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configuración predeterminada del Idle Timer
        UIApplication.shared.isIdleTimerDisabled = false
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // Método para soportar todas las orientaciones
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
    
    // Manejar cambios de estado de la aplicación
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restaurar comportamiento predeterminado del Idle Timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Asegurar que el Idle Timer esté habilitado al salir de la app
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

@main
struct WhisperJournal10_1App: App {
    
    static func logout() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    init() {
        // Asegúrate de que isAuthenticated esté configurado en false por defecto
        if UserDefaults.standard.object(forKey: "isAuthenticated") == nil {
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
        
        // Migrar transcripciones si está autenticado, de forma asíncrona
        if isAuthenticated {
            DispatchQueue.main.async {
                FirestoreService.shared.migrateExistingTranscriptionsToAlgolia { error in
                    if let error = error {
                        print("Error migrando transcripciones: \(error.localizedDescription)")
                    } else {
                        print("Transcripciones migradas exitosamente")
                    }
                }
            }
        }
    }
   
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .onAppear {
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
            }
        }
    }
}
