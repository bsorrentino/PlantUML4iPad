//
//  PlantUMLDoc+Menu.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 28/12/23.
//

import SwiftUI

struct PlantUMLDocumentMenu: View {
    
    enum MenuItem {
        case Menu
        case HandDrawn
        case HandWritten
    }
    
    @Binding var doc: PlantUMLDocument
    @State var activeScreen:MenuItem = .Menu
    
    var body: some View {
        
        switch( activeScreen ) {
        case .Menu:
            Menu
        case .HandDrawn:
            Text( "Hand Drawn" )
        case .HandWritten:
            PlantUMLDocumentView( document: PlantUMLDocumentProxy( document: $doc  ))
            // [Document based app shows 2 back chevrons on iPad](https://stackoverflow.com/a/74245034/521197)
                .toolbarRole(.navigationStack)

        }
    }
}

extension PlantUMLDocumentMenu {

    var Menu:some View {
        HStack(alignment:.center ) {
            Spacer(minLength: 100)
            
            VStack(alignment: .center, spacing: 30) {
                Button {
                    activeScreen = .HandDrawn
                } label: {
                    Label( "Hand Drawn", systemImage: "pencil")
                        .font(.largeTitle)
                }
                Divider()
                Button {
                    activeScreen = .HandWritten
                } label: {
                    Label( "Hand Written", systemImage: "keyboard")
                        .font(.largeTitle)
                    
                }
            }
            .padding(30)
            .background( Color.gray.opacity(0.2) )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.tertiary, lineWidth: 2)
            )
            Spacer(minLength: 100)
        }

    }
}


#Preview {
    
    PlantUMLDocumentMenu(
        doc: .constant(PlantUMLDocument())
    )
}
