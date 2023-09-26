//
//  CommonUtilitiesAndStyles.swift
//  Aerotas Tools
//
//  Created by Roberto Molina on 9/26/23.
//  Updated for macOS 14 and Swift 5.x
//

import SwiftUI

// MARK: - Button Styles

struct AerotasButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 50) // Explicitly set the frame size here
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// MARK: - Text Styles

struct HeadingTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundColor(Color.primary)
    }
}

// MARK: - Color Palette

extension Color {
    static let aerotasBlue = Color.blue // Replace with actual color from your asset catalog
}

// MARK: - Common Utilities

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
