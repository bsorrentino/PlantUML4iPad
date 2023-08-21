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
    
    @State private var text =
        """

        """
    
    var body: some View {
        NavigationView {
            
            CodeViewer(
                content: $text,
                mode: .dot,
                darkTheme: .monokai,
                lightTheme: .chrome,
                isReadOnly: false,
                fontSize: 15
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Pushed reload!")
                        NotificationCenter.default.post(name: NSNotification.Name("reload"), object: nil)
                    }) {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload")
                    }
                }
            }
            
        }
        .navigationViewStyle(.stack)
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
