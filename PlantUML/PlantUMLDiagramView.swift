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
    //    if isScaleToFit {
    //        PlantUMLDiagramViewFit
    //            .frame( width: geometry.size.width, height: geometry.size.height )
    //    }
    //    else {
    //        ScrollView([.horizontal, .vertical], showsIndicators: true) {
    //            PlantUMLDiagramView( url: document.buildURL(), contentMode: .fill )
    //                .frame( minWidth: geometry.size.width)
    //        }
    //        .frame( minWidth: geometry.size.width, minHeight: geometry.size.height )
    //    }
    
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
//        .border(Color.red)
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
