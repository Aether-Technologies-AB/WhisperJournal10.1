//
//  ProfileDetailView.swift
//  WhisperJournal10.1
//
//  Created by andree on 5/02/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct ProfileDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Encabezado de perfil
                headerSection
                
                // Secciones de perfil
                profileSections
                
                // Botón de cerrar sesión
                logoutButton
                
                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: loadUserData)
    }
    
    private var headerSection: some View {
        VStack {
            // Inicial del usuario
            Group {
                if let user = Auth.auth().currentUser, let email = user.email {
                    let initial = String(email.first ?? "U").uppercased()
                    Text(initial)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            
            // Nombre y correo
            Text(userName.isEmpty ? "Nombre de Usuario" : userName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(userEmail)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var profileSections: some View {
        VStack(spacing: 15) {
            // Sección de Planes
            profileSection(title: "Planes",
                           systemImage: "creditcard",
                           action: { print("Ver Planes") })
            
            // Sección de Configuración
            profileSection(title: "Configuración",
                           systemImage: "gear",
                           action: { print("Abrir Configuración") })
            
            // Sección de Mis Transcripciones
            profileSection(title: "Mis Transcripciones",
                           systemImage: "doc.text",
                           action: { print("Ver Transcripciones") })
        }
    }
    
    private func profileSection(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var logoutButton: some View {
        Button(action: logout) {
            Text("Cerrar Sesión")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
    }
    
    private func loadUserData() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? ""
            // Aquí podrías cargar más información del usuario si es necesario
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            // Navegar de vuelta a la pantalla de inicio de sesión
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}

struct ProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileDetailView()
        }
    }
}
