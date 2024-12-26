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
            .padding()
        }
        .padding()
        .sheet(isPresented: $showingRegistration) {
            RegisterView(showingRegistration: $showingRegistration)
        }
    }

    private func login() {
        guard let storedUsername = UserDefaults.standard.string(forKey: "username"),
              let storedPassword = UserDefaults.standard.string(forKey: "password") else {
            loginError = "No hay usuarios registrados"
            return
        }

        if username == storedUsername && password == storedPassword {
            isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
        } else {
            loginError = "Credenciales incorrectas"
        }
    }
}
