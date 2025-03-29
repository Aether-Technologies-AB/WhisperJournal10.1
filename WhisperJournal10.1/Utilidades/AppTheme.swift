//
//  AppTheme.swift
//  WhisperJournal10.1
//
//  Created by andree on 26/03/25.
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let background = Color(hex: "F5F7FA")
        static let accent = Color(hex: "1E3A5F")
        static let accentLight = Color(hex: "2A4A7F")
        static let text = Color(hex: "2D3748")
        static let secondaryText = Color(hex: "718096")
        static let buttonBackground = Color(hex: "E2E8F0")
        static let cardBackground = Color.white
        static let error = Color(hex: "63171B") // Dark red, not bright
    }
    
    // MARK: - Dimensions
    struct Dimensions {
        static let cornerRadius: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let iconSize: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        struct ShadowConfig {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
        
        static let subtle = ShadowConfig(
            color: .black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowConfig(
            color: .black.opacity(0.15),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    // MARK: - Text Styles
    struct TextStyle {
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let heading = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let subheading = Font.system(size: 17, weight: .medium, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
    }
    
    // MARK: - Button Styles
    struct ButtonStyle {
        static func primary() -> some SwiftUI.ButtonStyle {
            return GradientButtonStyle(startColor: Colors.accent,
                                     endColor: Colors.accentLight,
                                     textColor: .white)
        }
        
        static func secondary() -> some SwiftUI.ButtonStyle {
            return GradientButtonStyle(startColor: Colors.buttonBackground,
                                     endColor: Colors.buttonBackground,
                                     textColor: Colors.text)
        }
    }
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions
extension View {
    func applyShadow(_ config: AppTheme.Shadows.ShadowConfig) -> some View {
        self.shadow(color: config.color,
                   radius: config.radius,
                   x: config.x,
                   y: config.y)
    }
}

// MARK: - Custom Button Style
struct GradientButtonStyle: ButtonStyle {
    let startColor: Color
    let endColor: Color
    let textColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.TextStyle.subheading)
            .foregroundColor(textColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [startColor, endColor]),
                             startPoint: .leading,
                             endPoint: .trailing)
            )
            .cornerRadius(AppTheme.Dimensions.buttonCornerRadius)
            .applyShadow(AppTheme.Shadows.subtle)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
