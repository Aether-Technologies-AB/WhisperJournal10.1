//
//  ForgotPasswordView.swift
//  WhisperJournal10.1
//
//  Created by andree on 11/01/25.
//
import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack {
                Text(NSLocalizedString("forgot_password_title", comment: "Forgot Password title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black) // Color del Texto del Título: Negro
                    .padding()

                TextField(NSLocalizedString("email_placeholder", comment: "Email placeholder"), text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6)) // Gris claro (systemGray6)
                    .cornerRadius(25) // Forma ovalada
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5) // Gris con opacidad del 20%

                Button(NSLocalizedString("send_reset_email_button", comment: "Send Reset Email button")) {
                    sendPasswordReset()
                }
                .foregroundColor(.white) // Color del Texto del Botón: Blanco
                .padding()
                .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)) // Gradiente de azul a púrpura
                .cornerRadius(25) // Forma ovalada
                .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5) // Púrpura con opacidad del 40%
                .padding()
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(NSLocalizedString("message_title", comment: "Message title")), message: Text(message), dismissButton: .default(Text("OK")) {
                        // Redirigir a la pantalla de inicio de sesión después de mostrar la alerta
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
            .padding()
            .background(Color.white.edgesIgnoringSafeArea(.all)) // Color de Fondo de la Vista Principal: Blanco
            .navigationTitle(NSLocalizedString("forgot_password_nav_title", comment: "Forgot Password navigation title"))
        }
    }

    private func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = NSLocalizedString("error_sending_reset_email", comment: "Error sending reset email") + ": \(error.localizedDescription)"
            } else {
                message = NSLocalizedString("reset_email_sent", comment: "Reset email sent message")
            }
            showingAlert = true
        }
    }
}
