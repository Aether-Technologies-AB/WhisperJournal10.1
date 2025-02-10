//
//  ProfileView.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/02/25.
//


import SwiftUI
import FirebaseAuth
import UIKit

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
                menuOption(title: NSLocalizedString("profile_menu_profile", comment: "Profile menu option"), systemImage: "person")
                menuOption(title: NSLocalizedString("profile_menu_plans", comment: "Plans menu option"), systemImage: "creditcard", url: "https://nestofmemories.com/pricing")
                menuOption(title: NSLocalizedString("profile_menu_settings", comment: "Settings menu option"), systemImage: "gear")
                
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
            Text(Auth.auth().currentUser?.email ?? NSLocalizedString("profile_default_user", comment: "Default user"))
                .font(.headline)
            Text("WhisperJournal")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private func menuOption(title: String, systemImage: String, url: String? = nil) -> some View {
        Button(action: {
            if let urlString = url, let webURL = URL(string: urlString) {
                UIApplication.shared.open(webURL)
            } else {
                // Acciones para otras opciones de menú
                print("Seleccionado: \(title)")
            }
        }) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
            }
            .padding(.horizontal)
        }
    }
    
    private var logoutOption: some View {
        Button(action: logout) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                Text(NSLocalizedString("profile_logout", comment: "Logout button"))
                    .foregroundColor(.red)
            }
            .padding()
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
