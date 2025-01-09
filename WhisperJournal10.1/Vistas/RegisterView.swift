//
//  RegisterView.swift
//  WhisperJournal10.1
//
//  Created by andree on 25/12/24.
//
import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @Binding var showingRegistration: Bool
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var registrationError: String = ""

    var body: some View {
        VStack {
            Text("Registrarse")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            TextField("Correo electrónico", text: $username)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
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

            Button("Registrarse") {
                register()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func register() {
        guard password == confirmPassword else {
            registrationError = "Las contraseñas no coinciden"
            return
        }

        Auth.auth().createUser(withEmail: username, password: password) { authResult, error in
            if let error = error {
                registrationError = "Error al registrarse: \(error.localizedDescription)"
                return
            }
            isAuthenticated = true
            showingRegistration = false
        }
    }
}
