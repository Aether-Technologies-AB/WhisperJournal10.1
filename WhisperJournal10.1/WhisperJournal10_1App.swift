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
import UserNotifications

// Clase para gestionar la navegación desde notificaciones
class NotificationManager {
    static let shared = NotificationManager()
    
    // ID de la transcripción seleccionada desde una notificación
    var selectedTranscriptionId: String? = nil
    
    private init() {}
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configuración predeterminada del Idle Timer
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Establecer el delegado para manejar notificaciones
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Método para manejar cuando se toca una notificación
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Obtener el ID de la transcripción desde userInfo
        let userInfo = response.notification.request.content.userInfo
        if let transcriptionId = userInfo["transcriptionId"] as? String {
            // Guardar el ID para usarlo cuando la app esté lista
            NotificationManager.shared.selectedTranscriptionId = transcriptionId
            print("Notificación tocada para transcripción ID: \(transcriptionId)")
        }
        
        completionHandler()
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
    
    // Estado para controlar si se debe mostrar la vista de detalle de transcripción
    @State private var showTranscriptionDetail = false
    @State private var selectedTranscriptionId: String? = nil
    
    init() {
        // Asegúrate de que isAuthenticated esté configurado en false por defecto
        if UserDefaults.standard.object(forKey: "isAuthenticated") == nil {
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
        
        // Asegurarnos de que Firebase esté configurado antes de usar Auth
        // Firebase ya se configura en el AppDelegate, así que aquí solo verificamos
        
        // Solicitar permisos de notificaciones después de un breve retraso
        // para asegurar que Firebase esté completamente inicializado
        let isUserAuthenticated = isAuthenticated // Crear una copia local
        
        // Retrasar la solicitud de notificaciones para asegurar que Firebase esté listo
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                if success {
                    print("Autorización para notificaciones concedida")
                    // Programar notificaciones semanales si está autenticado
                    if isUserAuthenticated {
                        // Asegurarse de estar en el hilo principal
                        DispatchQueue.main.async {
                            NotificationService.shared.scheduleWeeklyMemories()
                        }
                    }
                } else if let error = error {
                    print("Error al solicitar autorización para notificaciones: \(error.localizedDescription)")
                }
            }
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
   
    // Método para abrir la transcripción desde una notificación
    func openTranscriptionDetail(transcriptionId: String) {
        guard let username = Auth.auth().currentUser?.email else { return }
        
        // Buscar la transcripción por ID
        FirestoreService.shared.fetchTranscriptionById(username: username, transcriptionId: transcriptionId) { transcription, error in
            if let error = error {
                print("Error al cargar la transcripción: \(error.localizedDescription)")
                return
            }
            
            if let transcription = transcription {
                // Presentar la vista de edición (que muestra los detalles)
                DispatchQueue.main.async {
                    let editView = EditTranscriptionView(
                        transcription: transcription,
                        onSave: { _ in
                            // No necesitamos hacer nada especial al guardar
                        }
                    )
                    
                    // Presentar la vista
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        let hostingController = UIHostingController(rootView: editView)
                        rootViewController.present(
                            hostingController,
                            animated: true,
                            completion: nil
                        )
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
                        
                        // Verificar si hay una transcripción seleccionada desde una notificación
                        if let transcriptionId = NotificationManager.shared.selectedTranscriptionId {
                            // Guardar el ID y limpiar el manager
                            self.selectedTranscriptionId = transcriptionId
                            NotificationManager.shared.selectedTranscriptionId = nil
                            self.showTranscriptionDetail = true
                            
                            // Mostrar la transcripción seleccionada
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                openTranscriptionDetail(transcriptionId: transcriptionId)
                            }
                        }
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
