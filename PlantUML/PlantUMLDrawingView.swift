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
            canvas: .constant(PKCanvasView(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000))),
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
    @State var isScrollEnabled = true
    @State var isUseDrawingTool = false
    @State var processing = false
    @State var processingLabel: String = "👀 Processing ..."
    @State private var processImageTask:Task<(),Never>? = nil
    
    var body: some View {
        
        ActivityView(isShowing: processing, label: processingLabel )  {
            
            DrawingView(canvas: $canvas,
                        isUsePickerTool: isUseDrawingTool,
                        isScrollEnabled: isScrollEnabled )
            .font(.system(size: 35))
            .navigationBarTitleDisplayMode(.inline)
            .foregroundColor(Color.purple)
            .navigationTitle( "\(document.fileName)   -   📝 Draw Diagram" )
            .navigationBarItems(trailing:
                                    HStack(spacing: 10) {
                
                Button(action: {
                    
                    isScrollEnabled.toggle()
                    //                            self.canvas.drawingGestureRecognizer.isEnabled = isScrollEnabled
                }) {
                    Label( "tools", systemImage:  isScrollEnabled ? "lock.open.fill" : "lock.fill" )
                        .foregroundColor(Color.orange)
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("drawing_lock")
                Button(action: {
                    isUseDrawingTool.toggle()
                }) {
                    Label( "tools", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .foregroundColor(Color.orange)
                        .labelStyle(.titleOnly)
                }
                .accessibilityIdentifier("drawing_tools")
                
                Divider()
                
                Button( action: processImage, label: {
                    Label( "process", systemImage: "eye")
                        .foregroundColor(Color.orange)
                        .labelStyle(.titleOnly)
                    
                })
                .accessibilityIdentifier("drawing_process")
            }
            )
        }
        .onCancel {
            processImageTask?.cancel()
        }
        .onAppear(perform: setupDrawing )
        .onDisappear( perform: updateDiagram )
    }
    
    private func toImage() -> UIImage {
        canvas.drawing.image(from: canvas.drawing.bounds, scale: 1)
    }
    
    private func saveImageToPhotos() {
        // saving to album
        UIImageWriteToSavedPhotosAlbum(toImage(), nil, nil, nil)
    }
    
    private func updateDiagram() {
        document.drawing = canvas.drawing.dataRepresentation()
    }
    
    private func setupDrawing() {
        
        guard let drawing = document.drawing else {
            return
        }
        
        do {
            
            let drawing = try PKDrawing(data: drawing)
            
            if DEMO_MODE {
                slowDrawingForDemo( canvas, drawing: drawing, timeInterval: 0.2)
            }
            else {
                canvas.drawing = drawing
            }
            
        }
        catch {
            fatalError( "failed to load drawing")
        }
    }
    
}


///
//MARK: - Vision extension
///
extension PlantUMLDrawingView : AgentExecutorDelegate {
    
    func progress(_ message: String) {
        processingLabel = message
    }
    
    fileprivate func saveData( _ data: Data, toFile fileName: String, inDirectory directory: FileManager.SearchPathDirectory ) {
        do {
            let dir = try FileManager.default.url(for: directory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let fileURL = dir.appendingPathComponent(fileName)
            print( "fileURL\n\(fileURL)")
            try data.write(to: fileURL)
        }
        catch {
            print( "error saving file \(error.localizedDescription)" )
        }
    }
    
    func processImage() {
        
        updateDiagram()
        
        // getting image from Canvas
        
        let backgroundColor:UIColor = (colorScheme == .dark ) ? .black : .white
        let image = toImage().withBackground(color: backgroundColor)
        
        if let imageData = image.pngData() {
            
            if SAVE_DRAWING_IMAGE {
                saveData(imageData, toFile: "image.png", inDirectory: .picturesDirectory)
            }
            
            processing.toggle()
            isUseDrawingTool = false
            service.status = .Ready
            processImageTask = Task {
                
                defer {
                    dismiss()
                }
                
                if let content = await service.processImageWithAgents( imageData: imageData, delegate: self ) {
                    
                    document.text = content
                    
                }
                
                //                let base64Image = imageData.base64EncodedString()
                //
                //                if let content = await service.processImageWithAgents( imageUrl: "data:image/png;base64,\(base64Image)", delegate: self ) {
                //
                //                    document.text = content
                //
                //                }
                
            }
            
        }
    }
    
}

// MARK: DEMO

fileprivate func slowDrawingForDemo( _ canvas: PKCanvasView, drawing: PKDrawing, timeInterval: TimeInterval  )  {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        
        canvas.drawing = PKDrawing()
        
        let strokes = drawing.strokes
        var current:Int = 0
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
            
            guard current < strokes.count else {
                timer.invalidate()
                return
            }
            let newDrawing = PKDrawing(strokes: [strokes[current]] )
            canvas.drawing.append(newDrawing  )
            current += 1
        }
    }
}
