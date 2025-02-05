//
//  ProfileView.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/02/25.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Contenido del menú desplegable
            HStack {
                userInitialCircle
                userDetails
                Spacer()
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 15) {
                menuOption(title: "Perfil", systemImage: "person")
                menuOption(title: "Planes", systemImage: "creditcard")
                menuOption(title: "Configuración", systemImage: "gear")
                
                Divider()
                
                logoutOption
            }
            .padding()
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var userInitialCircle: some View {
        Group {
            if let user = Auth.auth().currentUser, let email = user.email {
                let initial = String(email.first ?? "U").uppercased()
                Text(initial)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
    }
    
    private var userDetails: some View {
        VStack(alignment: .leading) {
            Text(Auth.auth().currentUser?.email ?? "Usuario")
                .font(.headline)
            Text("WhisperJournal")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.leading)
    }
    
    private func menuOption(title: String, systemImage: String) -> some View {
        Button(action: {
            // Acciones para cada opción
            print("Seleccionado: \(title)")
        }) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
            }
        }
    }
    
    private var logoutOption: some View {
        Button(action: {
            do {
                try Auth.auth().signOut()
                // Aquí podrías manejar la navegación de vuelta al login
            } catch {
                print("Error al cerrar sesión: \(error.localizedDescription)")
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                Text("Cerrar Sesión")
                    .foregroundColor(.red)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
