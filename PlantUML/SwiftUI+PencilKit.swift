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
    
    var type: PKInkingTool.InkType = .pencil
    var color: Color = .black
    let picker = PKToolPicker()
    
//    let eraser = PKEraserTool(.bitmap)
    
    func makeUIView(context: Context) -> PKCanvasView {
        if let data {
            do {
                canvas.drawing = try PKDrawing(data: data)
            }
            catch {
                fatalError( "failed to load drawing")
            }
        }

        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(type, color: UIColor(color))
        
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

#Preview {
    
    DrawingView( canvas: .constant(PKCanvasView()),
                 isUsePickerTool: .constant(true))
        

}
