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
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // ID de la transcripción seleccionada desde una notificación
    @Published var selectedTranscriptionId: String? = nil
    var retryCount = 0
    var maxRetries = 5
    
    func resetRetryCount() {
        retryCount = 0
    }
    
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
        print("Notificación recibida con userInfo: \(userInfo)")
        
        if let transcriptionId = userInfo["transcriptionId"] as? String {
            // Guardar el ID para usarlo cuando la app esté lista
            print("ID de transcripción extraído: \(transcriptionId)")
            NotificationManager.shared.selectedTranscriptionId = transcriptionId
            NotificationManager.shared.resetRetryCount()
        } else {
            print("Error: No se pudo extraer el ID de transcripción")
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
        print("Intentando abrir transcripción con ID: \(transcriptionId)")
        
        // Verificar autenticación primero
        guard let username = Auth.auth().currentUser?.email else {
            print("Error: Usuario no autenticado")
            // Guardar el ID para intentarlo más tarde cuando el usuario esté autenticado
            NotificationManager.shared.selectedTranscriptionId = transcriptionId
            return
        }
        
        // Agregar logs para depuración
        print("Buscando transcripción para usuario: \(username)")
        
        FirestoreService.shared.fetchTranscriptionById(username: username, transcriptionId: transcriptionId) { transcription, error in
            
            if let error = error {
                print("Error al buscar transcripción: \(error.localizedDescription)")
                
                // Sistema de reintentos
                if NotificationManager.shared.retryCount < NotificationManager.shared.maxRetries {
                    NotificationManager.shared.retryCount += 1
                    print("Reintentando (\(NotificationManager.shared.retryCount)/\(NotificationManager.shared.maxRetries))...")
                    
                    // Aumentar el retraso con cada reintento
                    let delay = Double(NotificationManager.shared.retryCount) * 1.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        self.openTranscriptionDetail(transcriptionId: transcriptionId)
                    }
                } else {
                    print("Número máximo de reintentos alcanzado")
                    NotificationManager.shared.resetRetryCount()
                }
                return
            }
            
            if let transcription = transcription {
                print("Transcripción encontrada, mostrando vista de recuerdo")
                
                // Presentar la nueva vista de recuerdo (similar a Apple Fotos)
                DispatchQueue.main.async {
                    // Usar la nueva MemoryView en lugar de TranscriptDetailView
                    let memoryView = MemoryView(transcription: transcription)
                    let hostingController = UIHostingController(rootView: memoryView)
                    
                    // Configurar presentación a pantalla completa con animación
                    hostingController.modalPresentationStyle = .fullScreen
                    hostingController.modalTransitionStyle = .crossDissolve
                    
                    // Presentar con animación
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(
                            hostingController,
                            animated: true,
                            completion: {
                                print("Vista de recuerdo presentada correctamente")
                                NotificationManager.shared.resetRetryCount()
                            }
                        )
                    } else {
                        print("Error: No se pudo obtener el controlador raíz")
                    }
                }
            } else {
                print("No se encontró la transcripción con ID: \(transcriptionId)")
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
                            print("Notificación detectada para transcripción: \(transcriptionId)")
                            // Guardar el ID y limpiar el manager
                            self.selectedTranscriptionId = transcriptionId
                            NotificationManager.shared.selectedTranscriptionId = nil
                            self.showTranscriptionDetail = true
                            
                            // Mostrar la transcripción seleccionada con un retraso mayor
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                openTranscriptionDetail(transcriptionId: transcriptionId)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        if let transcriptionId = NotificationManager.shared.selectedTranscriptionId {
                            print("Aplicación activada con transcripción pendiente: \(transcriptionId)")
                            NotificationManager.shared.selectedTranscriptionId = nil
                            
                            // Aumentar el retraso para asegurar que la app esté completamente cargada
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.openTranscriptionDetail(transcriptionId: transcriptionId)
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
