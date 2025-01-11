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
                    .padding()

                TextField(NSLocalizedString("email_placeholder", comment: "Email placeholder"), text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(NSLocalizedString("send_reset_email_button", comment: "Send Reset Email button")) {
                    sendPasswordReset()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(NSLocalizedString("message_title", comment: "Message title")), message: Text(message), dismissButton: .default(Text("OK")) {
                        // Redirigir a la pantalla de inicio de sesión después de mostrar la alerta
                        presentationMode.wrappedValue.dismiss()
                    })
                }
            }
            .navigationTitle(NSLocalizedString("forgot_password_nav_title", comment: "Forgot Password navigation title"))
        }
    }

    private func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = "\(NSLocalizedString("reset_email_error", comment: "Reset email error")): \(error.localizedDescription)"
            } else {
                message = NSLocalizedString("reset_email_sent", comment: "Reset email sent message")
            }
            showingAlert = true
        }
    }
}
