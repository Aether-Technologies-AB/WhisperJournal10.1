//
//  LoginView.swift
//  WhisperJournal10.1
//
//  Created by andree on 21/12/24.

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginError: String = ""
    @State private var showingRegistration = false
    @State private var showingForgotPassword = false

    var body: some View {
        VStack {
            Text(NSLocalizedString("login_title", comment: "Login title"))
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

            if !loginError.isEmpty {
                Text(loginError)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(NSLocalizedString("login_button", comment: "Login button")) {
                login()
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Button(NSLocalizedString("register_button", comment: "Register button")) {
                showingRegistration.toggle()
            }
            .padding()
            .sheet(isPresented: $showingRegistration) {
                RegisterView(showingRegistration: $showingRegistration, isAuthenticated: $isAuthenticated)
            }

            Button(NSLocalizedString("forgot_password_button", comment: "Forgot Password button")) {
                showingForgotPassword.toggle()
            }
            .padding()
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }

            // Botón de Google Sign-In
            Button(action: {
                signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .padding()
    }

    private func login() {
        Auth.auth().signIn(withEmail: username, password: password) { authResult, error in
            if let error = error {
                loginError = "\(NSLocalizedString("login_error", comment: "Login error")): \(error.localizedDescription)"
                return
            }
            isAuthenticated = true
        }
    }

    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            loginError = "Error: No root view controller found"
            return
        }
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                loginError = "Error signing in with Google: \(error.localizedDescription)"
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    loginError = "Error signing in with Google: \(error.localizedDescription)"
                } else {
                    isAuthenticated = true
                }
            }
        }
    }
}
