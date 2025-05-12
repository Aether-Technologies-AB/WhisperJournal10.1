//
//  MemoryView.swift
//  WhisperJournal10.1
//
//  Created by andree on 11/05/25.
//

import Foundation
import SwiftUI

struct MemoryView: View {
    let transcription: Transcription
    @State private var animationPhase = 0
    @State private var showFullView = false
    @Environment(\.presentationMode) var presentationMode
    @State private var loadedImages: [UIImage] = []
    @State private var isLoadingImages = false
    
    var body: some View {
        ZStack {
            // Fondo con gradiente suave
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Encabezado con información temporal
                VStack {
                    Text(getTimeAgoString(from: transcription.date))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    Text(transcription.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(animationPhase > 0 ? 1 : 0)
                .animation(.easeInOut(duration: 1), value: animationPhase)
                
                // Imágenes si existen
                if !loadedImages.isEmpty && animationPhase > 1 {
                    TabView {
                        ForEach(loadedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .padding()
                                .scaleEffect(animationPhase > 2 ? 1 : 0.8)
                                .animation(.easeInOut(duration: 1.5), value: animationPhase)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                }
                
                // Texto de la transcripción
                if animationPhase > 2 {
                    ScrollView {
                        Text(transcription.text)
                            .font(.body)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 1), value: animationPhase)
                }
                
                // Etiquetas si existen
                if !transcription.tags.isEmpty && animationPhase > 2 {
                    HStack {
                        Text(NSLocalizedString("detail_tags_label", comment: ""))
                            .font(.headline)
                        Text(transcription.tags)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .opacity(animationPhase > 2 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animationPhase)
                }
                
                // Botones de acción
                if animationPhase > 3 {
                    HStack(spacing: 20) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(NSLocalizedString("close_button", comment: ""))
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // Abrir en vista de detalle normal
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                // Primero cerrar la vista actual
                                presentationMode.wrappedValue.dismiss()
                                
                                // Esperar a que se cierre la vista actual antes de abrir la nueva
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    let detailView = TranscriptDetailView(transcription: transcription)
                                    let hostingController = UIHostingController(rootView: detailView)
                                    hostingController.modalPresentationStyle = .fullScreen
                                    rootViewController.present(hostingController, animated: true) {
                                        print("Vista de detalle presentada correctamente")
                                    }
                                }
                            }
                        }) {
                            Text(NSLocalizedString("view_details", comment: ""))
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .opacity(animationPhase > 3 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: animationPhase)
                }
            }
            .padding()
        }
        .onAppear {
            loadImages()
            startAnimationSequence()
        }
    }
    
    private func loadImages() {
        guard let imagePaths = transcription.imageLocalPaths, !imagePaths.isEmpty else { return }
        
        isLoadingImages = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let images = imagePaths.compactMap { path -> UIImage? in
                if let image = PersistenceController.shared.loadImage(filename: path) {
                    return image
                }
                return nil
            }
            
            DispatchQueue.main.async {
                isLoadingImages = false
                loadedImages = images
            }
        }
    }
    
    private func startAnimationSequence() {
        // Secuencia de animación por fases
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationPhase = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                animationPhase = 2
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animationPhase = 3
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        animationPhase = 4
                    }
                }
            }
        }
    }
    
    private func getTimeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date, to: Date())
        
        if let years = components.year, years > 0 {
            return String(format: NSLocalizedString("years_ago_title", comment: ""), years)
        } else if let months = components.month, months > 0 {
            return String(format: NSLocalizedString("months_ago_title", comment: ""), months)
        } else {
            return NSLocalizedString("recent_memory_title", comment: "")
        }
    }
}
