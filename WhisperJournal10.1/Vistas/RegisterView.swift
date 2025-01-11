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
        VStack {
            Text(NSLocalizedString("register_title", comment: "Register title"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            TextField(NSLocalizedString("email_placeholder", comment: "Email placeholder"), text: $username)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField(NSLocalizedString("password_placeholder", comment: "Password placeholder"), text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField(NSLocalizedString("confirm_password_placeholder", comment: "Confirm Password placeholder"), text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !registrationError.isEmpty {
                Text(registrationError)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(NSLocalizedString("register_button", comment: "Register button")) {
                register()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Button(NSLocalizedString("cancel_button", comment: "Cancel button")) {
                showingRegistration = false
            }
            .padding()
        }
    }

    private func register() {
        guard password == confirmPassword else {
            registrationError = NSLocalizedString("passwords_do_not_match", comment: "Passwords do not match error")
            return
        }

        Auth.auth().createUser(withEmail: username, password: password) { authResult, error in
            if let error = error {
                registrationError = "\(NSLocalizedString("registration_error", comment: "Registration error")): \(error.localizedDescription)"
            } else {
                guard let user = authResult?.user else { return }
                saveUserToFirestore(user: user)
            }
        }
    }

    private func saveUserToFirestore(user: User) {
        let db = Firestore.firestore()
        let email = user.email ?? ""
        let emailDocumentID = email.replacingOccurrences(of: ".", with: "_").replacingOccurrences(of: "@", with: "_")
        
        db.collection("users").document(emailDocumentID).setData([
            "email": email,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                registrationError = "\(NSLocalizedString("save_user_error", comment: "Save user error")): \(error.localizedDescription)"
            } else {
                isAuthenticated = true
                showingRegistration = false
            }
        }
    }
}
