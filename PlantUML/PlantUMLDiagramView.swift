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

struct PlantUMLScrollableDiagramView : View {
    
    var url: URL?
    var width: CGFloat
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            PlantUMLDiagramView( url: url )
                .frame( width: width )
        }
    }
    
}


struct PlantUMLDiagramView: UIViewRepresentable {
 
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

struct PlantUMLPreviw_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLDiagramView( url: URL( string: "http://www.soulsoftware.it" )! )
    }
}
