//
//  ContentViewWithDeepLink.swift
//  WhisperJournal10.1
//
//  Created by andree on 23/04/25.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import AVFoundation
import AudioKit

struct ContentViewWithDeepLink: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isRecording = false
    @State private var recordedText = ""
    @State private var transcriptionDate = Date()
    @State private var tags = ""
    @State private var selectedLanguage: String = "es-ES"
    @State private var showTranscriptionOptions = false
    @State private var selectedImage: UIImage?
    
    // Estados para la navegación desde notificaciones
    @State private var showTranscriptionDetail = false
    @State private var currentTranscription: Transcription?
    @State private var isLoadingTranscription = false
    
    // Referencia a la app principal para cargar transcripciones
    @EnvironmentObject private var app: WhisperJournalAppModel
    
    // Inicialización del audio
    let audioRecorder = AudioRecorder()
    let engine = AudioEngineMicrophone().audioEngine
    let mic: AudioEngine.InputNode
    
    init() {
        // Inicializa el motor de audio
        mic = engine.input ?? AudioEngine().input!
        
        // Verificar si hay una transcripción seleccionada desde una notificación
        if AppNavigation.shared.shouldNavigateToTranscription {
            _showTranscriptionDetail = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Fondo con gradiente
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        headerSection
                        
                        if isAuthenticated {
                            authenticatedContent
                        } else {
                            LoginView(isAuthenticated: $isAuthenticated)
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: isRecording)
                    .blur(radius: isProfileMenuOpen ? 5 : 0)
                    .disabled(isProfileMenuOpen)
                    .sheet(isPresented: $showNotificationsAccess) {
                        NotificationsAccessView()
                    }
                    
                    // Menú lateral
                    if isProfileMenuOpen {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation {
                                    isProfileMenuOpen = false
                                }
                            }
                        
                        profileSideMenu(geometry: geometry)
                            .transition(.move(edge: .trailing))
                    }
                    
                    // Overlay para mostrar la transcripción desde notificación
                    if isLoadingTranscription {
                        Color.black.opacity(0.3)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(
                                ProgressView(NSLocalizedString("loading_transcription", comment: ""))
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            )
                    }
                }
                .navigationTitle(NSLocalizedString("home_title", comment: "Home title"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(action: {
                        showNotificationsAccess = true
                    }) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    },
                    trailing: userIcon
                )
                .sheet(isPresented: $showImagePicker) {
                    ImagePickerView(selectedImage: $selectedImage,
                                    sourceType: activePickerType == .camera ? .camera : .photoLibrary)
                }
                .sheet(isPresented: $showProfile) {
                    ProfileView()
                }
                .fullScreenCover(isPresented: $showTranscriptionDetail) {
                    if let transcription = currentTranscription {
                        EditTranscriptionView(
                            transcription: transcription,
                            onSave: { _ in
                                // Limpiar el estado de navegación después de cerrar
                                AppNavigation.shared.resetNavigation()
                            }
                        )
                        .onDisappear {
                            // Limpiar el estado de navegación
                            AppNavigation.shared.resetNavigation()
                        }
                    }
                }
                .onAppear {
                    checkForDeepLink()
                }
                .onChange(of: AppNavigation.shared.shouldNavigateToTranscription) { shouldNavigate in
                    if shouldNavigate {
                        checkForDeepLink()
                    }
                }
            }
        }
    }
    
    // Función para verificar si hay una transcripción para abrir desde notificación
    private func checkForDeepLink() {
        if AppNavigation.shared.shouldNavigateToTranscription,
           let transcriptionId = AppNavigation.shared.selectedTranscriptionId {
            
            print("Detectada navegación a transcripción: \(transcriptionId)")
            isLoadingTranscription = true
            
            // Usar la app para cargar la transcripción
            WhisperJournal10_1App().loadTranscription(id: transcriptionId) { transcription in
                isLoadingTranscription = false
                
                if let transcription = transcription {
                    self.currentTranscription = transcription
                    self.showTranscriptionDetail = true
                    print("Transcripción cargada correctamente para mostrar")
                } else {
                    print("No se pudo cargar la transcripción")
                    // Mostrar un mensaje de error
                    // TODO: Implementar alerta de error
                }
            }
        }
    }
    
    // Aquí incluir el resto del código de ContentView
    // (headerSection, authenticatedContent, etc.)
    // ...
    
    // MARK: - Variables de estado de ContentView
    @State private var showAlert = false
    @State private var showProfile = false
    @State private var isProfileMenuOpen = false
    @State private var showNotificationsAccess = false
    @State private var showImagePicker = false
    @State private var activePickerType: ImagePickerType = .photoLibrary
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @StateObject private var audioEngineMicrophone = AudioEngineMicrophone()
    
    // MARK: - Enums
    enum ImagePickerType {
        case photoLibrary
        case camera
    }
    
    // MARK: - Placeholder para métodos requeridos de ContentView
    // Estos métodos deberían copiarse del ContentView original
    
    // Ícono de usuario en la barra de navegación
    private var userIcon: some View {
        Group {
            if let user = Auth.auth().currentUser, let email = user.email {
                let initial = String(email.first ?? "U").uppercased()
                Button(action: {
                    withAnimation {
                        isProfileMenuOpen.toggle()
                    }
                }) {
                    Text(initial)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            } else {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // Sección de encabezado
    private var headerSection: some View {
        Text(NSLocalizedString("app_title", comment: "App title"))
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
            )
    }
    
    // Menú lateral personalizado (placeholder - debe implementarse completamente)
    private func profileSideMenu(geometry: GeometryProxy) -> some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                // Encabezado del menú
                VStack(spacing: 20) {
                    // Imagen y datos del usuario
                    VStack(spacing: 15) {
                        userInitialCircle
                        
                        VStack(spacing: 5) {
                            Text(Auth.auth().currentUser?.email ?? NSLocalizedString("default_user", comment: "Default user name"))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("app_pro_title", comment: "Pro version title"))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 30)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Separador con degradado
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, 10)
                
                // Opciones del menú (placeholder)
                Text("Opciones del menú")
                    .padding()
                
                Spacer()
                
                // Botón de cerrar sesión
                Button(action: logout) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                        Text(NSLocalizedString("profile_logout", comment: "Logout button"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .frame(width: geometry.size.width * 0.75)
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 10)
            .edgesIgnoringSafeArea(.vertical)
        }
    }
    
    // Vista de inicial de usuario actualizada
    private var userInitialCircle: some View {
        Group {
            if let user = Auth.auth().currentUser, let email = user.email {
                let initial = String(email.first ?? "U").uppercased()
                Text(initial)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
    
    // Contenido para usuario autenticado (placeholder - debe implementarse completamente)
    private var authenticatedContent: some View {
        VStack {
            Text("Contenido autenticado")
            Text("Implementar según ContentView original")
        }
    }
    
    // Método para cerrar sesión
    private func logout() {
        WhisperJournal10_1App.logout()
        isAuthenticated = false
        isProfileMenuOpen = false
    }
}

// Modelo para la aplicación
class WhisperJournalAppModel: ObservableObject {
    // Propiedades y métodos que necesiten ser compartidos
}

// Vista previa
struct ContentViewWithDeepLink_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewWithDeepLink()
            .environmentObject(WhisperJournalAppModel())
    }
}
