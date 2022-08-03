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
 
struct PlantUMLDiagramView: UIViewRepresentable {
 
    var url: URL
 
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
 
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct PlantUMLPreviw_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLDiagramView( url: URL( string: "http://www.soulsoftware.it" )! )
    }
}
