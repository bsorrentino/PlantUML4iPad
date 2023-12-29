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
        PlantUMLDrawingView( onGeneratedScript: { _ in } )
            .preferredColorScheme(.dark)
    }
}

struct PlantUMLDrawingView: View {
    @Environment( \.colorScheme) var colorScheme
    @State var canvas = PKCanvasView()
    @State var isdraw = false
    @StateObject private var openAIService = OpenAIService()
    
    var onGeneratedScript: ( String ) -> Void
    
    var body: some View {
        
//        NavigationStack {
            
            DrawingView(canvas: $canvas, isdraw: $isdraw )
                .font(.system(size: 35))
                .navigationBarTitleDisplayMode(.inline)
                .foregroundColor(Color.purple)
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
    
    func vision( imageUrl: String ) async throws {
        
        guard let openai = openAIService.openAI else {
                return
        }
        
        let prompt =
        """
        Translate diagram within image in a plantUML script following rules below:

        1. every rectangle or icon must be translate in plantuml rectangle element with related label if any
        2. every rectangle that contains other rectangles must be translated in plantuml rectangle {}  element
        3. every label (word or phrase) outside rectangles: if close to arrow must be considered its label else it must be translated in plantuml note
        
        result must only be the plantuml script whitout any other comment
        """
        
        let query = ChatQuery(
            model: .gpt4_vision_preview,
            messages: [
                Chat(role: .user, content: [
                    ChatContent(text: prompt),
                    ChatContent(imageUrl: imageUrl)
                ])
            ],
            maxTokens: 2000
        )
        
        let result = try await openai.chats(query: query)
        
        let e = result.choices[0].message.content
            
        if case .string(let content) = e {
            self.onGeneratedScript( content )
        }
        
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
            
            Task {
                
                do {
                    try await vision( imageUrl: "data:image/png;base64,\(base64Image)" )
                }
                catch {
                    print( "error invoking vision api \(error.localizedDescription)" )
                }
            }
            
        }
        
    }

    
}

