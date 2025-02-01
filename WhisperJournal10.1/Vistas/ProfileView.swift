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
    @State private var userEmail: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(NSLocalizedString("profile_title", comment: "Profile title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let user = Auth.auth().currentUser {
                    Text("\(NSLocalizedString("email_label", comment: "Email label")): \(user.email ?? NSLocalizedString("email_not_available", comment: "Email not available"))")
                        .font(.title2)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                } else {
                    Text(NSLocalizedString("no_authenticated_user", comment: "No authenticated user"))
                        .font(.title2)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(NSLocalizedString("profile_navigation_title", comment: "Profile navigation title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("close_button", comment: "Close button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
