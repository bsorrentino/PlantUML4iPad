//
//  DrawingView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 28/12/23.
//

import SwiftUI
import PencilKit
import OpenAI

#Preview( "PlantUMLDrawingView") {
    NavigationStack {
        PlantUMLDrawingView( 
            canvas: .constant(PKCanvasView()),
            service: OpenAIService(),
            document: PlantUMLDocumentProxy(document:.constant(PlantUMLDocument()), fileName:"Untitled")
        )
            
    }
}

struct PlantUMLDrawingView: View {
    @Environment( \.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Binding var canvas:PKCanvasView
    @State var isdraw = false
    @ObservedObject var service:OpenAIService
    @ObservedObject var document: PlantUMLDocumentProxy
    
    var body: some View {
        
//        NavigationStack {
            
            DrawingView(canvas: $canvas, isdraw: $isdraw )
                .font(.system(size: 35))
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(Color.purple)
                .navigationTitle( document.fileName )
                .navigationBarItems(leading:
                    HStack {
                        Button( action: saveImage, label: {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.title)
                                .foregroundColor(Color.orange)
                        })
                        Button( action: processImage, label: {
                            Image(systemName: "eye.square")
                                .font(.title)
                                .foregroundColor(Color.orange)
                        }).padding( .top, 10)
                }, trailing: HStack(spacing: 15) {
                    
                    Button(action: {
                        isdraw.toggle()
                    }) {
                        Image(systemName: "rectangle.and.pencil.and.ellipsis")
                            .font(.title)
                            .foregroundColor(Color.orange)
                    }
                    
                })
            
            
//        }
    }
    
    private func image() -> UIImage {
        canvas.drawing.image(from: canvas.drawing.bounds, scale: 1)
    }
    
    func saveImage() {
        
        // saving to album
        
        UIImageWriteToSavedPhotosAlbum(image(), nil, nil, nil)
                
    }

}


///
//MARK: - Vision extension
///
extension PlantUMLDrawingView {
    
    func processImage() {
        
        // getting image from Canvas
        
        let backgroundColor:UIColor = (colorScheme == .dark ) ? .black : .white
        let image = image().withBackground(color: backgroundColor)

        if let imageData = image.pngData() {

            #if __SAVE_IMAGE
            do {
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("image.png")
                print( "fileURL\n\(fileURL)")
                try imageData.write(to: fileURL)
            }
            catch {
                print( "error saving file \(error.localizedDescription)" )
            }
            #endif
            
            let base64Image = imageData.base64EncodedString()
            
            Task {
                
                if let content = await service.vision( imageUrl: "data:image/png;base64,\(base64Image)" ) {
                    
                    document.text = content

                    dismiss()
                }

            }
            
        }
        
    }

    
}

