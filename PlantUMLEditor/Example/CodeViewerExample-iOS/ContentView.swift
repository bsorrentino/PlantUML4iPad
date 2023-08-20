//
//  ContentView.swift
//  CodeViewerExample-iOS
//
//  Created by Phuc on 07/09/2020.
//  Copyright © 2020 Dwarves Foundattion. All rights reserved.
//

import SwiftUI
import CodeViewer

struct ContentView: View {
    
    @State private var text =  """
        @startuml
        
        participant A
        
        @enduml
        """
    
    var body: some View {
        CodeViewer(
            content: $text,
            mode: .dot,
            darkTheme: .dracula,
            lightTheme: .chrome,
            isReadOnly: false,
            fontSize: 13
        )
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ForEach(ColorScheme.allCases, id: \.self) {
             ContentView()
                .preferredColorScheme($0)
                .previewDisplayName("\($0)")
        }
    }
}
