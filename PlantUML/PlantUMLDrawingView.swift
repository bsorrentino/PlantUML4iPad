//
//  DrawingView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 28/12/23.
//

import SwiftUI
import PencilKit
import AIAgent

#Preview( "PlantUMLDrawingView") {
    NavigationStack {
        PlantUMLDrawingView( 
            canvas: .constant(PKCanvasView()),
            service: OpenAIObservableService(),
            document: PlantUMLObservableDocument(document:.constant(PlantUMLDocument()), fileName:"Untitled")
        )
            
    }
}

struct PlantUMLDrawingView: View {
    @Environment( \.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Binding var canvas:PKCanvasView
    @ObservedObject var service:OpenAIObservableService
    @ObservedObject var document: PlantUMLObservableDocument
    @State var isUseDrawingTool = false
    @State var processing = false
    @State var processingLabel: String = "👀 Processing ..."
    @State private var processImageTask:Task<(),Never>? = nil
    
    var body: some View {
        
        ActivityView(isShowing: processing, label: processingLabel )  {
           
            DrawingView(canvas: $canvas, isUsePickerTool: $isUseDrawingTool, data: document.drawing )
                .font(.system(size: 35))
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(Color.purple)
                .navigationTitle( document.fileName )
                .navigationBarItems(leading:
                    HStack {
                        Button( action: processImage, label: {
                            Label( "process", systemImage: "eye")
                                .foregroundColor(Color.orange)
                                .labelStyle(.titleAndIcon)
                            
                        })
                    },trailing:
                        HStack(spacing: 15) {
                    
                        Button(action: {
                            isUseDrawingTool.toggle()
                        }) {
                            Label( "tools", systemImage: "rectangle.and.pencil.and.ellipsis")
                                .foregroundColor(Color.orange)
                                .labelStyle(.titleOnly)
                        }
                    
                    })
        }
        .onCancel {
            processImageTask?.cancel()
        }
        
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
extension PlantUMLDrawingView : AgentExecutorDelegate {
    
    func progress(_ message: String) {
        processingLabel = message
    }
        
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
            
            processing.toggle()
            isUseDrawingTool = false
            service.status = .Ready
            processImageTask = Task {
                
                do {
                    defer {
                        document.drawing = canvas.drawing.dataRepresentation()
                        dismiss()
                    }

                    if let content = await service.processImageWithAgents( imageUrl: "data:image/png;base64,\(base64Image)", delegate: self ) {
                        
                        document.text = content
                        
                    }
                }

            }
            
        }
        
    }

    
}

