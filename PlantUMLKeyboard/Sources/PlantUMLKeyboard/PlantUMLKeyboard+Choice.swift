//
//  PlantUMLKeyboard+Choice.swift
//  
//
//  Created by Bartolomeo Sorrentino on 11/03/23.
//

import SwiftUI



struct ChoiceKeyButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
//    @State private var showingSheet = false
    @State private var selection: Symbol?

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
            if let choices = symbol.additionalValues?.map({
                if let ref = try? Symbol.matchRef(in: $0 ), let choice = Symbol.references?.first(where: { s in s.id == ref }) {
                    return choice
                }
                return Symbol( id: symbol.id, value: String(format: symbol.value, $0 ) )
            }) {
                presentViewOnRootController(  ChoiceView( title: symbol.id, choices: choices, selection: $selection ) )

            }
        }
        label: {
            Label(symbol.id, systemImage: "list.bullet")
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .disabled( symbol.additionalValues == nil )
        .buttonStyle( TextKeyButtonStyle() )
        .onChange(of: selection) { _ in
            
            if let selection {
                
                onPressSymbol( selection )

            }
        }
//        .sheet( isPresented: $showingSheet ) {
//            ChoiceView( symbol: symbol )
//        }
    }
}

struct ChoiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var title: String
    var choices: [Symbol]
    @Binding var selection: Symbol?

    private func Navigation( content: () -> some View ) -> some View {
        if #available(iOS 16.0, *) {
            return NavigationStack( root: content )
        }
        else {
            return NavigationView( content: content )
        }
    }
    
    var body: some View {
        Navigation {
        
            List(choices, id: \.self, selection: $selection) {
                Text($0.id)
            }
            .onChange(of: selection) { _ in
                dismiss()
            }
            .navigationTitle( title )
            .toolbar {
                ToolbarItem( placement: .navigationBarTrailing ) {
                    Button {
                        dismiss()
                    }
                    label: {
                        Label(title, systemImage: "xmark")
                            .labelStyle( .iconOnly )
                    }
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        
        ForEach(ColorScheme.allCases, id: \.self) {
            
            ChoiceKeyButton(
                symbol:Symbol( id: "test", additionalValues: [ "Item1", "Item2", "item3" ] ),
                onPressSymbol: { _ in } )
                .preferredColorScheme($0)
        }
        
    }
}
