//
//  PlantUMLKeyboard+Choices.swift
//  
//
//  Created by Bartolomeo Sorrentino on 11/03/23.
//

import SwiftUI



struct ChoiceKeyButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
//    @State private var showingSheet = false
    @State private var selection: String?

    var symbol:Symbol
    var onPressSymbol: (Symbol) -> Void
    
    init(symbol: Symbol, onPressSymbol: @escaping (Symbol) -> Void) {
        self.symbol = symbol
        self.onPressSymbol = onPressSymbol
    }

    private func presentViewOnRootController<T : View>( _ view: T ) {
        getRootViewController()?.presentedViewController?.present(
            UIHostingController(rootView: view ),
            animated: true,
            completion: nil )

    }
    var body: some View {
        Button {
//            showingSheet.toggle()
            presentViewOnRootController(  ChoiceView( symbol: symbol, selection: $selection ) )
        }
        label: {
            Text(symbol.id)
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .disabled( symbol.additionalValues == nil )
        .buttonStyle( TextKeyButtonStyle() )
        .onChange(of: selection) { _ in
            let symbol = Symbol( id: symbol.id, value: selection )
            
            onPressSymbol( symbol )
        }
//        .sheet( isPresented: $showingSheet ) {
//            ChoiceView( symbol: symbol )
//        }
    }
}

struct ChoiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var symbol: Symbol
    @Binding var selection: String?


    func Navigation( content: () -> some View ) -> some View {
        if #available(iOS 16.0, *) {
            return NavigationStack( root: content )
        }
        else {
            return NavigationView( content: content )
        }
    }
    
    var body: some View {
        Navigation {
        
            List(symbol.additionalValues ?? [], id: \.self, selection: $selection) { name in
                Text(name)
            }
            .onChange(of: selection) { _ in
                dismiss()
            }
            .navigationTitle( symbol.value )
//            .toolbar {
//                EditButton()
//            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ChoiceKeyButton(
            symbol:Symbol( id: "test", additionalValues: [ "Item1", "Item2", "item3" ] ),
            onPressSymbol: { _ in } )
    }
}
