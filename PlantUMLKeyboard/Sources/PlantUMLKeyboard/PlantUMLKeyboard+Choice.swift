//
//  PlantUMLKeyboard+Choices.swift
//  
//
//  Created by Bartolomeo Sorrentino on 11/03/23.
//

import SwiftUI



struct ChoiceKeyButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingSheet = false
    
    var symbol:Symbol
    var onPressSymbol: (Symbol) -> Void
    
    init(symbol: Symbol, onPressSymbol: @escaping (Symbol) -> Void) {
        self.symbol = symbol
        self.onPressSymbol = onPressSymbol
    }

    var body: some View {
        Button {
            showingSheet.toggle()
        }
        label: {
            Text(symbol.id)
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .disabled( symbol.additionalValues == nil )
        .buttonStyle( TextKeyButtonStyle() )
        .sheet( isPresented: $showingSheet ) {
            ChoiceView( symbol: symbol )
        }
    }
}

struct ChoiceView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selection: String?

    var symbol: Symbol

    func Navigation( content: () -> some View ) -> some View {
        if #available(iOS 16.0, *) {
            return NavigationStack( root: content )
        }
        else {
            return NavigationView( content: content )
        }
    }
    
    var body: some View {
//        Navigation {
        
            List(symbol.additionalValues ?? [], id: \.self, selection: $selection) { name in
                Text(name)
            }
            .onChange(of: selection) { _ in
                // dismiss()
            }
            .navigationTitle( symbol.value )
//            .toolbar {
//                EditButton()
//            }
//        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ChoiceKeyButton(
            symbol:Symbol( id: "test", additionalValues: [ "Item1", "Item2", "item3" ] ),
            onPressSymbol: { _ in } )
    }
}
