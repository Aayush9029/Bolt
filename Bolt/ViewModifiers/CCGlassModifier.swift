//
//  CCGlassModifier.swift
//  Bolt
//
//  Created by Aayush Pokharel on 2023-04-28.
//

import MacControlCenterUI
import SwiftUI

struct CCGlassModifier: ViewModifier {
    let filled: Bool
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Group {
                    if !filled {
                        ZStack {
                            VisualEffect(.hudWindow, blendingMode: .withinWindow)
                        }
                    } else {
                        Color.white
                    }
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.primary.opacity(0.45), lineWidth: 0.25)
            )
            .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

            .contentShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func ccGlassButton(filled: Bool = false, padding: CGFloat = 12) -> ModifiedContent<Self, CCGlassModifier> {
        return modifier(CCGlassModifier(filled: filled, padding: padding))
    }
}

struct CCGlassModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello")
            .ccGlassButton()
            .padding()
    }
}
