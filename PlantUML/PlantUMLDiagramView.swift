//
//  PlantUMLPreviw.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 03/08/22.
//
// inspired by: https://www.appcoda.com/swiftui-wkwebview/

import SwiftUI

import SwiftUI
import WebKit
import Combine


struct PlantUMLDiagramView : View {
    var url: URL?
    var contentMode:ContentMode
    
    var body: some View {
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
    
}


struct PlantUMLDiagramView_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLDiagramView( url: URL( string: "https://picsum.photos/id/870/100/150" ), contentMode: .fill )
    }
}


///
/// OLD IMPLEMENTATION
///
///
private class PlantUMLDiagramState: ObservableObject {

    private var updateSubject = PassthroughSubject<URL, Never>()
    
    private var cancellabe:Cancellable?
    
    func subscribe( onUpdate update: @escaping ( URLRequest ) -> Void ) {
        
        if self.cancellabe == nil  {
            
            self.cancellabe = updateSubject
                .removeDuplicates()
                .debounce(for: .seconds(2), scheduler: RunLoop.main)
                .print()
                .map { URLRequest(url: $0 ) }
                .sink( receiveValue: update )

        }

    }
    
    func requestUpdate( forURL url:URL ) {
        updateSubject.send( url )
    }
}

private struct PlantUMLScrollableDiagramView : View {
    
    var url: URL?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            PlantUMLDiagramView_old( url: url )
        }
    }
    
}

private struct PlantUMLDiagramView_old: UIViewRepresentable {
 
    @StateObject private var state = PlantUMLDiagramState()
    
    var url: URL?
 
    func makeUIView(context: Context) -> WKWebView {
        
        let webView = WKWebView()
        
        state.subscribe( onUpdate: { request in
            webView.load(request)
        })
                
        return webView
    }
 
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = url else {
            return
        }
        
        state.requestUpdate( forURL: url)
        
    }
}
