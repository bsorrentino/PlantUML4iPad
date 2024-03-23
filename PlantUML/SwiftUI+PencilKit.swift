//
//  SwiftUI+PencilKit.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 29/12/23.
//

import SwiftUI
import PencilKit

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


struct DrawingView: UIViewRepresentable {
    // to capture drawings for saving into albums
    @Binding var canvas: PKCanvasView
    @Binding var isUsePickerTool: Bool
    var data: Data?
    
    @State var picker = PKToolPicker()
    
//    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        if let data {
            do {
                
                let drawing = try PKDrawing(data: data)
                
                if DEMO_MODE {
                    slowDrawingForDemo(drawing, timeInterval: 0.4)
                }
                else {
                    canvas.drawing = drawing
                }
                
            }
            catch {
                fatalError( "failed to load drawing")
            }
        }

        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: UIColor(.black))
        
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // updating the tool whenever the view updates
        if( isUsePickerTool ) {
            picker.addObserver(canvas)
            picker.setVisible(true, forFirstResponder: uiView)
        }
        else {
            picker.setVisible(false, forFirstResponder: uiView)
            picker.removeObserver(canvas)
        }
        

        
    }
}

// MARK: DEMO
extension DrawingView {
    
    fileprivate func slowDrawingForDemo( _ drawing: PKDrawing, timeInterval: TimeInterval  )  {
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
    

}


#Preview {
    
    DrawingView( canvas: .constant(PKCanvasView()),
                 isUsePickerTool: .constant(true))
        

}
