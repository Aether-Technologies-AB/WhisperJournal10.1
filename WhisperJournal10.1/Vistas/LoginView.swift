//
//  LoginView.swift
//  WhisperJournal10.1
//
//  Created by andree on 21/12/24.

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginError: String = ""
    @State private var showingRegistration = false
    @State private var showingForgotPassword = false

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("login_title", comment: "Login title"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.black) // Color del Texto del Título: Negro

            // Campo de texto para email
            TextField(NSLocalizedString("email_placeholder", comment: "Email placeholder"), text: $username)
                .padding()
                .background(Color(.systemGray6)) // Color de Fondo de los Campos de Texto: Gris claro (systemGray6)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Color de la Sombra de los Campos de Texto: Gris con opacidad del 20%

            // Campo de texto para contraseña
            SecureField(NSLocalizedString("password_placeholder", comment: "Password placeholder"), text: $password)
                .padding()
                .background(Color(.systemGray6)) // Color de Fondo de los Campos de Texto: Gris claro (systemGray6)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Color de la Sombra de los Campos de Texto: Gris con opacidad del 20%

            if !loginError.isEmpty {
                Text(loginError)
                    .foregroundColor(.red) // Color del Texto de Error: Rojo
                    .font(.footnote)
                    .padding(.top, 5)
            }

            // Botón de iniciar sesión
            Button(action: {
                login()
            }) {
                Text(NSLocalizedString("login_button", comment: "Login button"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Color de Fondo del Botón de Iniciar Sesión: Gradiente de azul a púrpura
                    .cornerRadius(20)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Color de la Sombra del Botón de Iniciar Sesión: Púrpura con opacidad del 40%
            }

            // Botón de registro
            Button(action: {
                showingRegistration.toggle()
            }) {
                Text(NSLocalizedString("register_button", comment: "Register button"))
                    .font(.headline)
                    .foregroundColor(.blue) // Color del Texto del Botón de Registro: Azul
            }
            .sheet(isPresented: $showingRegistration) {
                RegisterView(showingRegistration: $showingRegistration, isAuthenticated: $isAuthenticated)
            }

            // Botón de "Olvidé mi contraseña"
            Button(action: {
                showingForgotPassword.toggle()
            }) {
                Text(NSLocalizedString("forgot_password_button", comment: "Forgot Password button"))
                    .font(.subheadline)
                    .foregroundColor(.blue) // Color del Texto del Botón de "Olvidé mi Contraseña": Azul
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }

            // Botón de Google Sign-In
            Button(action: {
                signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text(NSLocalizedString("google_signin_button", comment: "Sign in with Google button"))
                }
                .font(.headline)
                .foregroundColor(.blue) // Color del Texto del Botón de Google Sign-In: Azul
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white) // Color de Fondo del Botón de Google Sign-In: Blanco
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: 5) // Color de la Sombra del Botón de Google Sign-In: Gris con opacidad del 40%
            }
        }
        .padding()
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Color de Fondo de la Vista Principal: Blanco
    }

    private func login() {
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if let error = error {
                loginError = NSLocalizedString("login_error", comment: "Login error message") + ": \(error.localizedDescription)"
                return
            }
            isAuthenticated = true
        }
    }

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            loginError = NSLocalizedString("no_root_view_controller_error", comment: "No root view controller error message")
            return
        }
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                loginError = NSLocalizedString("google_signin_error", comment: "Error signing in with Google") + ": \(error.localizedDescription)"
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    loginError = NSLocalizedString("google_signin_error", comment: "Error signing in with Google") + ": \(error.localizedDescription)"
                } else {
                    isAuthenticated = true
                }
            }
        }
    }
}
