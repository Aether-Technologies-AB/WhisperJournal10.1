//
//  LoginView.swift
//  WhisperJournal10.1
//
//  Created by andree on 21/12/24.
import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginError: String = ""
    @State private var showingRegistration = false

    var body: some View {
        VStack {
            TextField("Nombre de usuario", text: $username)
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
        FirestoreService.shared.fetchUser(username: username) { storedPassword, error in
            if let storedPassword = storedPassword, storedPassword == password {
                UserDefaults.standard.set(username, forKey: "username")
                isAuthenticated = true
            } else {
                loginError = "Nombre de usuario o contraseña incorrectos."
            }
        }
    }
}
