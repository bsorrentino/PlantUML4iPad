//
//  PlantUMLPreviw.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 03/08/22.
//
// inspired by: [How to Display Web Page Using WKWebView](https://www.appcoda.com/swiftui-wkwebview/)

import SwiftUI

import SwiftUI
import WebKit
import Combine

struct PlantUMLDiagramView : View {
    @State private var isScaleToFit = true
    @State private var diagramImage:UIImage?
    
    var url: URL?
    var contentMode:ContentMode {
        if isScaleToFit { .fit } else { .fill }
    }
    
    var diagramView:some View {
        CachedAsyncImage(url: url, scale: 1 ) { phase in
            
                if let image = phase.image {
                    
                    // if the image is valid
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                    
                }
                else if let _ = phase.error {
                    EmptyView()
                }
                else {
                    // showing progress view as placeholder
                    VStack(alignment: .center ) {
                        Image("uml")
                            .resizable()
                            .frame( width: 200, height: 150)
                        ProgressView()
                            .font(.largeTitle)
                    }
                }
            
        }
        
    }
    
    var body: some View {
        
        VStack {
            if isScaleToFit {
                diagramView
            }
            else {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    diagramView
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ScaleToFitButton()
                ShareDiagramButton()
            }
        }
        .navigationBarTitle(Text( "📈 Diagram Preview" ), displayMode: .inline)

    }
    
}

extension PlantUMLDiagramView {
    
    
    func ScaleToFitButton() -> some View {
        
        Toggle("fit image", isOn: $isScaleToFit)
            .toggleStyle(ScaleToFitToggleStyle())
        
    }
    
    func ShareDiagramButton() -> some View {
        Button(action: {
            if let image = self.asUIImage() {
                diagramImage = image
            }
        }) {
            ZStack {
                Image(systemName:"square.and.arrow.up")
                SwiftUIActivityViewController( uiImage: $diagramImage )
            }
            
        }
//        .disabled( diagramImage == nil )
        
    }
    
}
#Preview {
    NavigationStack {
        PlantUMLDiagramView( url: URL( string: "https://picsum.photos/id/870/100/150" ) )
    }
}

