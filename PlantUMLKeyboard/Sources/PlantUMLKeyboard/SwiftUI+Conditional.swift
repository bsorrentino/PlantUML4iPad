//
//  SwiftUI+Conditional.swift
//  PlantUMLApp
//
//  Created by Bartolomeo Sorrentino on 18/01/23.
//

import SwiftUI

//
// This extension lets us add the .if modifier to our Views and will only apply the modifiers we add if the condition is met.
//
// inspired by [Conditional modifier](https://designcode.io/swiftui-handbook-conditional-modifier)
extension View {
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, then transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, then transformThen: (Self) -> Content, else transformElse: (Self) -> Content ) -> some View {
        if condition {
            transformThen(self)
        } else {
            transformElse(self)
        }
    }

}
