//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 14/09/22.
//

import SwiftUI

public struct ShowKeyboardAccessoryButton: View {
    
    @Binding var show: Bool
    
    public init( show: Binding<Bool> ) {
        self._show = show
    }
    
    public var body: some View {
        Button(action: {
            show.toggle()
        }) {
            Image(systemName: "keyboard.badge.ellipsis")
                .foregroundColor(.black.opacity(0.5))
        }

    }
}

public struct ShowKeyboardButton: View {
    
    @Binding var show: Bool
    
    public init( show: Binding<Bool> ) {
        self._show = show
    }
    
    public var body: some View {
        Button(action: {
            show.toggle()
        }) {
            Label( "PlantUML Keyboard", systemImage: "keyboard.badge.ellipsis" )
                .labelStyle(.titleAndIcon)
        }

    }
}

struct ShowKeyboardButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ShowKeyboardButton( show: Binding.constant(false))
            ShowKeyboardAccessoryButton( show: Binding.constant(false))
        }
    }
}
