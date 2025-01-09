//
//  LoginView.swift
//  WhisperJournal10.1
//
//  Created by andree on 21/12/24.
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginError: String = ""
    @State private var showingRegistration = false
    @State private var showingForgotPassword = false

    var body: some View {
        VStack {
            Text("Iniciar Sesión")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            TextField("Correo electrónico", text: $username)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Contraseña", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !loginError.isEmpty {
                Text(loginError)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Iniciar sesión") {
                login()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Button("Registrarse") {
                showingRegistration.toggle()
            }
            .padding()
            .sheet(isPresented: $showingRegistration) {
                RegisterView(showingRegistration: $showingRegistration, isAuthenticated: $isAuthenticated)
            }

            Button("Olvidé mi contraseña") {
                showingForgotPassword.toggle()
            }
            .padding()
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
        .padding()
    }

    private func login() {
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if let error = error {
                loginError = "Error al iniciar sesión: \(error.localizedDescription)"
                return
            }
            isAuthenticated = true
        }
    }
}
