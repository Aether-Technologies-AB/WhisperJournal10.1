//
//  RegisterView.swift
//  WhisperJournal10.1
//
//  Created by andree on 25/12/24.
//
import SwiftUI

struct RegisterView: View {
    @Binding var showingRegistration: Bool
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var registrationError: String = ""

    var body: some View {
        VStack {
            TextField("Nombre de usuario", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Contraseña", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Confirmar Contraseña", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !registrationError.isEmpty {
                Text(registrationError)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Registrar") {
                register()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Button("Cancelar") {
                showingRegistration = false
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .padding()
    }

    private func register() {
        guard !username.isEmpty else {
            registrationError = "El nombre de usuario no puede estar vacío."
            return
        }

        guard !password.isEmpty else {
            registrationError = "La contraseña no puede estar vacía."
            return
        }

        guard password == confirmPassword else {
            registrationError = "Las contraseñas no coinciden."
            return
        }

        FirestoreService.shared.saveUser(username: username, password: password) { error in
            if let error = error {
                registrationError = "Error al registrar el usuario: \(error.localizedDescription)"
            } else {
                // Guardar las credenciales en UserDefaults
                UserDefaults.standard.set(username, forKey: "username")
                UserDefaults.standard.set(password, forKey: "password")
                // Redirigir a la pantalla de inicio de sesión
                showingRegistration = false
                // Iniciar sesión automáticamente
                login()
            }
        }
    }

    private func login() {
        FirestoreService.shared.fetchUser(username: username) { storedPassword, error in
            if let storedPassword = storedPassword, storedPassword == password {
                UserDefaults.standard.set(username, forKey: "username")
                isAuthenticated = true
            } else {
                registrationError = "Error al iniciar sesión después del registro."
            }
        }
    }
}
