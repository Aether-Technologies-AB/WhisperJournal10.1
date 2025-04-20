//
//  NotificationsAccessView.swift
//  WhisperJournal10.1
//
//  Created by andree on 18/04/25.
//

import Foundation
import SwiftUI

struct NotificationsAccessView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Ícono de notificaciones
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .padding(.top, 40)
                
                Text(NSLocalizedString("notifications_title", comment: "Notifications settings title"))
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(NSLocalizedString("notifications_description", comment: "Configure your notifications to relive important moments"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showingNotificationSettings = true
                }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text(NSLocalizedString("configure_notifications", comment: "Configure notifications button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    NotificationService.shared.scheduleWeeklyMemories()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text(NSLocalizedString("enable_weekly_notifications", comment: "Enable weekly notifications button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    NotificationService.shared.cancelAllNotifications()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text(NSLocalizedString("disable_notifications", comment: "Disable notifications button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitle(NSLocalizedString("notifications_nav_title", comment: "Notifications navigation title"), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("close_button", comment: "Close button")) {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
            }
        }
    }
}

struct NotificationsAccessView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsAccessView()
    }
}
