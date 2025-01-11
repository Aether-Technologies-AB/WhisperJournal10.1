//
//  WhisperJournal10_1App.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
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
