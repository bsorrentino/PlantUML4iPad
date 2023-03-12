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
            Label(symbol.id, systemImage: "list.bullet")
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .disabled( symbol.additionalValues == nil )
        .buttonStyle( TextKeyButtonStyle() )
        .onChange(of: selection) { _ in
            
            if let selection {

                let value = String(format: symbol.value, selection )

                let symbol = Symbol( id: symbol.id, value: value )
                
                onPressSymbol( symbol )

            }
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

    private var items: [String] {
        symbol.additionalValues ?? []
    }

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
        
            List(items, id: \.self, selection: $selection) { name in
                Text(name)
            }
            .onChange(of: selection) { _ in
                dismiss()
            }
            .navigationTitle( symbol.id )
            .toolbar {
                ToolbarItem( placement: .navigationBarTrailing ) {
                    Button {
                        dismiss()
                    }
                    label: {
                        Label(symbol.id, systemImage: "xmark")
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
