//
//  PlantUMLKeyboard.swift
//
//

import SwiftUI
import UIKit
import LineEditor

public struct PlantUMLKeyboardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var selectedTab:String
    var onHide:() -> Void
    var onPressSymbol: (Symbol) -> Void
    
    public init(selectedTab: Binding<String>, onHide: @escaping () -> Void, onPressSymbol: @escaping (Symbol) -> Void) {
        self._selectedTab = selectedTab
        self.onHide = onHide
        self.onPressSymbol = onPressSymbol
    }
    
    public var body : some View {
        
        ZStack(alignment: .topLeading) {
            
            TabView( selection: $selectedTab ) {
                
                ForEach( plantUMLSymbols ) { group in
                    ContentView( group )
                        .tabItem {
                            Label( group.name, systemImage: "list.dash")
                                .labelStyle(.titleOnly)
                        }
                        .tag( group.name )
                        //.background(Color.gray.opacity(0.7))


                }
            }
            .frame(maxWidth: .infinity )
            //.background(Color.gray.opacity(0.7))
            .cornerRadius(25)
            
            HideButton()
        }
        
        .padding()
    }
    
  
    private func keyButton( from symbol: Symbol ) -> some View {
        Group {
            if symbol.type == "color" {
                ColorKeyButton( symbol: symbol, onPressSymbol: onPressSymbol )
            }
            else if symbol.type == "choice" {
                ChoiceKeyButton( symbol: symbol, onPressSymbol: onPressSymbol )
            }
            else {
                TextKeyButton( symbol: symbol)
            }
        }
    }
    
    func ContentView( _ group: PlantUMLSymbolGroup ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack(spacing: 15){
                
                ForEach( Array(group.rows.enumerated()), id: \.offset) { rowIndex, i in
                    
                    HStack(spacing: 10) {
                        
                        ForEach( Array(i.enumerated()), id: \.offset ) { cellIndex, symbol in
                            
                            VStack {
                                keyButton(from: symbol)
                            }

                        }
                        
                    }
                }
            }
            .padding(.top)

        }
    }
    
}

struct TextKeyButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    // [Button border with corner radius in Swift UI](https://stackoverflow.com/a/62544642/521197)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .foregroundColor( (colorScheme == .dark) ? .white : .black )
            .background( (colorScheme == .dark) ? .black : .white )
            .cornerRadius(5)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke((colorScheme == .dark) ? .white : .black, lineWidth: 1)
            }
    }
}


// MARK: Plain Button Extension
extension PlantUMLKeyboardView {
    
    func TextKeyButton( symbol: Symbol ) -> some View {
        
        Button {
            onPressSymbol(symbol)
        } label: {
            Text(symbol.id)
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .buttonStyle( TextKeyButtonStyle() )
    }
    
    func HideButton() -> some View  {
        HStack {
            Button(action: onHide) {
                Image(systemName: "xmark")
                    .foregroundColor( (colorScheme == .dark) ? .white : .black)
            }
            Spacer()
        }

    }

}


struct PlantUMLKeyboardView_Previews: PreviewProvider {
        
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            PlantUMLKeyboardView( selectedTab: .constant("general"), onHide: { }, onPressSymbol: { _ in } )
                .previewInterfaceOrientation(.landscapeLeft)
                .preferredColorScheme($0)
        }
        
    }
}
