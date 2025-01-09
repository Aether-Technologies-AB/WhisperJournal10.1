//
//  ForgotPasswordView.swift
//  WhisperJournal10.1
//
//  Created by andree on 6/01/25.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var showingAlert = false
    @State private var navigateToLogin = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Recuperar Contraseña")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                TextField("Correo electrónico", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Enviar correo de recuperación") {
                    sendPasswordReset()
                }
                .buttonStyle(.borderedProminent)
                .padding()

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                }

                NavigationLink(value: navigateToLogin) {
                    EmptyView()
                }
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Recuperación de Contraseña"), message: Text(message), dismissButton: .default(Text("OK")) {
                    if message.contains("Correo de recuperación enviado con éxito") {
                        navigateToLogin = true
                    }
                })
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView(isAuthenticated: .constant(false))
            }
        }
    }

    private func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = "Error al enviar el correo de recuperación: \(error.localizedDescription)"
            } else {
                message = "Correo de recuperación enviado con éxito. Por favor, revisa tu bandeja de entrada."
            }
            showingAlert = true
        }
    }
}
