//
//  LoginView.swift
//  WhisperJournal10.1
//
//  Created by andree on 20/12/24.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticated: Bool = false
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Iniciar Sesión")
                    .font(.largeTitle)
                    .padding()

                TextField("Nombre de usuario", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Contraseña", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    authenticateUser()
                }) {
                    Text("Iniciar Sesión")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.headline)
                }
                .padding()

                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text("Nombre de usuario o contraseña incorrectos"), dismissButton: .default(Text("OK")))
            }
            .background(
                NavigationLink(destination: ContentView(), isActive: $isAuthenticated) {
                    EmptyView()
                }
            )
        }
    }

    func authenticateUser() {
        // Lógica de autenticación (esto es solo un ejemplo)
        if username == "andree" && password == "123456" {
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
            isAuthenticated = true
        } else {
            showAlert = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
