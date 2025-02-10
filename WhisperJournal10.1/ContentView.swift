




import SwiftUI
import AVFoundation
import AudioKit
import AudioKitUI
import FirebaseAuth
import Speech
import UIKit

struct ContentView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var isRecording = false
    @State private var recordedText = ""
    @State private var transcriptionDate = Date()
    @State private var tags = ""
    @State private var selectedLanguage: String = "es-ES"
    @State private var showTranscriptionOptions = false
    @State private var audioVisualizer: AudioVisualizerView?
    @State private var selectedImage: UIImage?
    enum ImagePickerType {
        case photoLibrary
        case camera
    }
    @State private var showImagePicker = false
    @State private var activePickerType: ImagePickerType = .photoLibrary
    @State private var showAlert = false
    @State private var showProfile = false
    @State private var isProfileMenuOpen = false
    
    @StateObject private var audioEngineMicrophone = AudioEngineMicrophone()
    let audioRecorder: AudioRecorder
    let engine: AudioEngine
    let mic: AudioEngine.InputNode

    init() {
        // Inicializa audioRecorder
        audioRecorder = AudioRecorder()
        
        // Usa el motor de audio de AudioEngineMicrophone
        engine = AudioEngineMicrophone().audioEngine
        mic = engine.input ?? AudioEngine().input!
    }
    
    // Resto del código permanece igual...

    private func startAudioEngine() {
        audioEngineMicrophone.start()
    }

    private func stopAudioEngine() {
        audioEngineMicrophone.stop()
    }

    private func startRecording() {
        audioRecorder.setLanguageCode(selectedLanguage)
        audioRecorder.startRecording { transcription in
            self.recordedText = transcription
            self.transcriptionDate = Date()
        }
        isRecording = true
        audioEngineMicrophone.stop()
    }

    private func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
    }
    
    // Método para verificar la disponibilidad de la cámara
    private func checkCameraAvailability() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
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
                }
                .navigationTitle(NSLocalizedString("home_title", comment: "Home title"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: userIcon)
                
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text(NSLocalizedString("camera_unavailable_title", comment: "Camera unavailable title")),
                        message: Text(NSLocalizedString("camera_unavailable_message", comment: "Camera unavailable message")),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage,
                              sourceType: activePickerType == .camera ? .camera : .photoLibrary)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
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

    // Menú lateral personalizado
    private func profileSideMenu(geometry: GeometryProxy) -> some View {
        HStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado del usuario
                HStack {
                    userInitialCircle
                    
                    VStack(alignment: .leading) {
                        Text(Auth.auth().currentUser?.email ?? "Usuario")
                            .font(.headline)
                        Text("WhisperJournal")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                Divider()
                
                // Opciones del menú
                menuOption(title: "Perfil", systemImage: "person") {
                    print("Ir a Perfil")
                    isProfileMenuOpen = false
                }
                
                menuOption(title: "Planes", systemImage: "creditcard") {
                    if let url = URL(string: "https://nestofmemories.com/pricing") {
                        UIApplication.shared.open(url)
                    }
                    isProfileMenuOpen = false
                }
                menuOption(title: "Configuración", systemImage: "gear") {
                    print("Abrir Configuración")
                    isProfileMenuOpen = false
                }
                
                Spacer()
                
                // Botón de cerrar sesión
                Button(action: logout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Cerrar Sesión")
                            .foregroundColor(.red)
                    }
                    .padding()
                }
            }
            .frame(width: geometry.size.width * 0.7)
            .background(Color(UIColor.systemBackground))
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    // Vista de inicial de usuario
    private var userInitialCircle: some View {
        Group {
            if let user = Auth.auth().currentUser, let email = user.email {
                let initial = String(email.first ?? "U").uppercased()
                Text(initial)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
    }

    // Función para crear opciones del menú
    private func menuOption(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
            }
            .padding(.horizontal)
        }
    }

    // Contenido para usuario autenticado
    private var authenticatedContent: some View {
        VStack(spacing: 20) {
            languageSelector
            
            recordingSection
            
            if !recordedText.isEmpty {
                transcriptionDisplay
                photoOptions
            }
            
            actionButtons
            
            Spacer()
            
            logoutButton
        }
    }

    // Selector de idioma
    private var languageSelector: some View {
        Menu {
            Button("🇪🇸 " + NSLocalizedString("spanish", comment: "Spanish")) { selectedLanguage = "es-ES" }
            Button("🇬🇧 " + NSLocalizedString("english", comment: "English")) { selectedLanguage = "en-US" }
            Button("🇸🇪 " + NSLocalizedString("swedish", comment: "Swedish")) { selectedLanguage = "sv-SE" }
        } label: {
            HStack {
                Image(systemName: "globe")
                Text("\(NSLocalizedString("select_language", comment: "Select Language")): \(selectedLanguage)")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }

    // Sección de grabación
    private var recordingSection: some View {
        VStack {
            if isRecording {
                AudioVisualizerView()
                    .frame(height: 100)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }

            Button(action: toggleRecording) {
                recordingButtonContent
            }
            .buttonStyle(RecordingButtonStyle(isRecording: isRecording))
            .frame(maxWidth: .infinity)
        }
    }

    // Contenido del botón de grabación
        private var recordingButtonContent: some View {
            HStack {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                Text(isRecording ?
                    NSLocalizedString("stop_button", comment: "Stop button") :
                    NSLocalizedString("record_button", comment: "Record button"))
                    .font(.caption)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: isRecording ? [Color.red, Color.pink] : [Color.green, Color.teal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
        }

    // Visualización de transcripción
    private var transcriptionDisplay: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("transcription_label", comment: "Transcription label"))
                .font(.headline)

            Text(recordedText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .transition(.slide)
        }
        .padding()
    }

    // Opciones de foto
    private var photoOptions: some View {
        VStack {
            HStack(spacing: 15) {
                // Botón de Biblioteca de Fotos
                Button(action: {
                    openImagePicker(sourceType: .photoLibrary)
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                        
                        Text(NSLocalizedString("choose_from_library", comment: "Choose from library"))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                
                // Botón de Cámara
                Button(action: {
                    openImagePicker(sourceType: .camera)
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                        
                        Text(NSLocalizedString("take_photo", comment: "Take photo"))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                }
            }
            .padding(.vertical, 10)
        }
    }

    // Botones de acción
    private var actionButtons: some View {
        VStack(spacing: 15) {
            Button(action: saveTranscription) {
                Text(NSLocalizedString("save_transcription", comment: "Save Transcription button"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.7), Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    .font(.caption)
            }

            NavigationLink(destination: TranscriptionListView()) {
                Text(NSLocalizedString("view_saved_transcriptions", comment: "View Saved Transcriptions button"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.7), Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                    .font(.caption)
            }
        }
    }

    // Botón de logout
    private var logoutButton: some View {
        Button(action: logout) {
            Text(NSLocalizedString("logout_button", comment: "Logout button"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.red.opacity(0.7), Color.red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.4), radius: 8, x: 0, y: 4)
                .font(.caption)
        }
    }

    // Métodos de grabación y guardado
    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

  /*  private func startRecording() {
        audioRecorder.setLanguageCode(selectedLanguage)
        audioRecorder.startRecording { transcription in
            self.recordedText = transcription
            self.transcriptionDate = Date()
        }
        isRecording = true
        engine.stop()
    }

    private func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
        try? engine.start()
    }
*/
    private func saveTranscription() {
        guard !recordedText.isEmpty,
              let username = Auth.auth().currentUser?.email else { return }

        // Guardar imagen si existe
        var imageLocalPaths: [String] = []
        if let selectedImage = selectedImage {
            if let imagePath = PersistenceController.shared.saveImage(selectedImage) {
                imageLocalPaths.append(imagePath)
            }
        }

        FirestoreService.shared.saveTranscription(
            username: username,
            text: recordedText,
            date: transcriptionDate,
            tags: tags,
            imageLocalPaths: imageLocalPaths.isEmpty ? nil : imageLocalPaths
        ) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                resetFields()
                selectedImage = nil
            }
        }
    }

    private func resetFields() {
        recordedText = ""
        tags = ""
        selectedImage = nil
    }

  

    private func logout() {
        WhisperJournal10_1App.logout()
        isAuthenticated = false
        isProfileMenuOpen = false
    }

   /* private func startAudioEngine() {
        try? engine.start()
    }

    private func stopAudioEngine() {
        engine.stop()
    }
*/
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .camera {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                showAlert = true
                return
            }
            activePickerType = .camera
        } else {
            activePickerType = .photoLibrary
        }
        showImagePicker = true
    }
}

// Estilos personalizados
struct RecordingButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: isRecording ? [Color.red, Color.pink] : [Color.green, Color.teal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Vista de visualización de audio
struct AudioVisualizerView: View {
    @State private var bars: [CGFloat] = Array(repeating: 20, count: 20)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { index in
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 3, height: bars[index])
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                bars = bars.map { _ in
                    CGFloat.random(in: 20...100)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
