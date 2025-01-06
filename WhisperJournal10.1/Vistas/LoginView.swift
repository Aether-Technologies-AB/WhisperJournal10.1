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

    var body: some View {
        VStack {
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

            Button("Registrar") {
                showingRegistration = true
            }
            .buttonStyle(.bordered)
            .padding()
            .sheet(isPresented: $showingRegistration) {
                RegisterView(showingRegistration: $showingRegistration, isAuthenticated: $isAuthenticated)
            }
        }
        .padding()
    }

    private func login() {
        Auth.auth().signIn(withEmail: username, password: password) { result, error in
            if let error = error {
                loginError = "Error: \(error.localizedDescription)"
            } else {
                UserDefaults.standard.set(username, forKey: "username")
                isAuthenticated = true
            }
        }
    }
}
