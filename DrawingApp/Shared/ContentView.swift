//
//  ContentView.swift
//  Shared
//
//  Created by Temiloluwa on 06/10/2020.
//

import SwiftUI
import PencilKit
import OpenAI

struct ContentView: View {
    var body: some View {
        
        Home()
    }
}

#Preview {
    ContentView()
}


///
/// [how to set a background color in UIimage in swift programming](https://stackoverflow.com/a/53500161/521197)
///
extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }
        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

struct Home: View {
    
    @State var canvas = PKCanvasView()
    @State var isdraw = false
    
    // default is pen
    
    var body: some View {
        
        NavigationStack {
            
            // Drawing View......
            
            DrawingView(canvas: $canvas, isdraw: $isdraw )
                .navigationTitle("Canvas")
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
extension Home {
    
    func vision( imageUrl: String ) async throws {
        
        let prompt =
        """
        Translate diagram within image in a plantUML script following rules below:

        1. every rectangle or icon must be translate in plantuml rectangle element with related label if any
        2. every rectangle that contains other rectangles must be translated in plantuml rectangle {}  element
        3. every label (word or phrase) outside rectangles: if close to arrow must be considered its label else it must be translated in plantuml note
        
        result must only be the plantuml script whitout any other comment
        """
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_KEY"]
        
        let openai = OpenAI(apiToken: apiKey!)
            
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
            print( "\(content)" )
        }
        
    }
    
    func processImage() {
        
        // getting image from Canvas
        
        let image = image().withBackground(color: .white)

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

struct DrawingView: UIViewRepresentable {
    // to capture drawings for saving into albums
    @Binding var canvas: PKCanvasView
    @Binding var isdraw: Bool
    
    var type: PKInkingTool.InkType = .pencil
    var color: Color = .black
    let picker = PKToolPicker()
    
//    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(type, color: UIColor(color))
        
        self.canvas.becomeFirstResponder()
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // updating the tool whenever the view updates
        picker.addObserver(canvas)
        picker.setVisible(isdraw, forFirstResponder: uiView)
    
        
    }
}
