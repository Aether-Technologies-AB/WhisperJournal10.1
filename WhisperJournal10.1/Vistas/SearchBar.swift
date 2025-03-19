//
//  SearchBar.swift
//  WhisperJournal10.1
//
//  Created by andree on 18/03/25.
//

import Foundation
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar o hacer una pregunta...", text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit(onSearch)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !text.isEmpty {
                Button("Buscar", action: onSearch)
                    .foregroundColor(.blue)
            }
        }
    }
}
