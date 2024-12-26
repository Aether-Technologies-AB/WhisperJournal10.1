//
//  RegisterView.swift
//  WhisperJournal10.1
//
//  Created by andree on 25/12/24.
//

import SwiftUI

struct RegisterView: View {
    @Binding var showingRegistration: Bool
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
        }
        .padding()
    }

    private func register() {
        guard !username.isEmpty else {
            registrationError = "El nombre de usuario no puede estar vacío"
            return
        }

        guard password.count >= 6 else {
            registrationError = "La contraseña debe tener al menos 6 caracteres"
            return
        }

        guard password == confirmPassword else {
            registrationError = "Las contraseñas no coinciden"
            return
        }

        // Guardar usuario
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(password, forKey: "password")
        showingRegistration = false
    }
}
