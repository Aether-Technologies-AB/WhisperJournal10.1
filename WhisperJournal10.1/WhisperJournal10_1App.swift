//
//  WhisperJournal10_1App.swift
//  WhisperJournal10.1
//
//  Created by andree on 14/12/24.
//

import SwiftUI

@main
struct WhisperJournal10_1App: App {
    let persistenceController = PersistenceController.shared
    @State private var isAuthenticated: Bool = UserDefaults.standard.bool(forKey: "isAuthenticated")

    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
