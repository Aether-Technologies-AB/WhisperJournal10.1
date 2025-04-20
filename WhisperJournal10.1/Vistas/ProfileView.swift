//
//  ProfileView.swift
//  WhisperJournal10.1
//
//  Created by andree on 1/02/25.
//


import SwiftUI
import Firebase
import UserNotifications
import FirebaseAuth
import UIKit

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingPlans = false
    @State private var showingSettings = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmationAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header con información del usuario
                    VStack(spacing: 20) {
                        userInitialCircle
                        userDetails
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Sección de estadísticas
                    statsSection
                        .padding(.vertical)
                    
                    // Opciones del menú
                    menuSection
                        .padding(.top)
                    
                    Spacer()
                }
            }
            .navigationBarTitle(NSLocalizedString("profile_title", comment: "Profile view title"), displayMode: .large)
            .navigationBarItems(trailing: closeButton)
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
    
    private var userInitialCircle: some View {
        Group {
            if let user = Auth.auth().currentUser, let email = user.email {
                let initial = String(email.first ?? "U").uppercased()
                Text(initial)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
            }
        }
    }
    
    private var userDetails: some View {
        VStack(spacing: 8) {
            Text(Auth.auth().currentUser?.email ?? NSLocalizedString("profile_default_user", comment: "Default user"))
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("WhisperJournal Pro")
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            statItem(count: "10", title: NSLocalizedString("stats_recordings", comment: "Recordings count"))
            
            Divider()
                .frame(height: 40)
            
            statItem(count: "5", title: NSLocalizedString("stats_active_days", comment: "Active days count"))
            
            Divider()
                .frame(height: 40)
            
            statItem(count: "2", title: NSLocalizedString("stats_tags", comment: "Tags count"))
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private func statItem(count: String, title: String) -> some View {
        VStack(spacing: 8) {
            Text(count)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var menuSection: some View {
        VStack(spacing: 16) {
            menuOption(
                title: NSLocalizedString("menu_account_settings", comment: "Account settings option"),
                systemImage: "person.circle.fill",
                color: .blue
            ) {
                showingSettings = true
            }
            
            menuOption(
                title: NSLocalizedString("menu_plans_subscriptions", comment: "Plans and subscriptions option"),
                systemImage: "star.circle.fill",
                color: .yellow
            ) {
                if let url = URL(string: "https://nestofmemories.com/pricing") {
                    UIApplication.shared.open(url)
                }
            }
            
            menuOption(
                title: NSLocalizedString("menu_help_support", comment: "Help and support option"),
                systemImage: "questionmark.circle.fill",
                color: .green
            ) {
                // Acción para ayuda
            }
            
            menuOption(
                title: "Configuración de recordatorios",
                systemImage: "bell.circle.fill",
                color: .orange
            ) {
                showingNotificationSettings = true
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Botón de cerrar sesión
            Button(action: logout) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                    Text(NSLocalizedString("menu_logout", comment: "Logout button"))
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private func menuOption(title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
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
