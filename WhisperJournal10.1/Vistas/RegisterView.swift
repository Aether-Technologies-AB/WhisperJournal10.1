//
//  RegisterView.swift
//  WhisperJournal10.1
//
//  Created by andree on 25/12/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @Binding var showingRegistration: Bool
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var registrationError: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("register_title", comment: "Register title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.customText)
                .padding()

            TextField(NSLocalizedString("email_placeholder", comment: "Email placeholder"), text: $username)
                .padding()
                .background(Color.customFieldBackground)
                .cornerRadius(10)
                .shadow(color: .customFieldShadow, radius: 5, x: 0, y: 5)

            SecureField(NSLocalizedString("password_placeholder", comment: "Password placeholder"), text: $password)
                .padding()
                .background(Color.customFieldBackground)
                .cornerRadius(10)
                .shadow(color: .customFieldShadow, radius: 5, x: 0, y: 5)

            SecureField(NSLocalizedString("confirm_password_placeholder", comment: "Confirm Password placeholder"), text: $confirmPassword)
                .padding()
                .background(Color.customFieldBackground)
                .cornerRadius(10)
                .shadow(color: .customFieldShadow, radius: 5, x: 0, y: 5)

            if !registrationError.isEmpty {
                Text(registrationError)
                    .foregroundColor(.customErrorText)
                    .font(.footnote)
                    .padding(.top, 5)
            }

            Button(action: {
                register()
            }) {
                Text(NSLocalizedString("register_button", comment: "Register button"))
                    .font(.headline)
                    .foregroundColor(.customButtonText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.customButtonGradientStart, .customButtonGradientEnd], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(20)
                    .shadow(color: .customButtonShadow, radius: 10, x: 0, y: 5)
            }

            Button(action: {
                showingRegistration = false
            }) {
                Text(NSLocalizedString("cancel_button", comment: "Cancel button"))
                    .font(.headline)
                    .foregroundColor(.customLinkText)
            }
            .padding()
        }
        .padding()
        .background(Color.customBackground.edgesIgnoringSafeArea(.all))
    }

    private func register() {
        guard !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            registrationError = NSLocalizedString("registration_error_empty_fields", comment: "Error message for empty fields")
            return
        }

        guard password == confirmPassword else {
            registrationError = NSLocalizedString("registration_error_password_mismatch", comment: "Error message for password mismatch")
            return
        }

        Auth.auth().createUser(withEmail: username, password: password) { authResult, error in
            if let error = error {
                registrationError = error.localizedDescription
            } else {
                saveUserToFirestore()
                isAuthenticated = true
                showingRegistration = false
            }
        }
    }

    private func saveUserToFirestore() {
        let db = Firestore.firestore()
        let user = ["username": username]
        db.collection("users").document(username).setData(user) { error in
            if let error = error {
                print("Error al guardar el usuario en Firestore: \(error.localizedDescription)")
            }
        }
    }
}
