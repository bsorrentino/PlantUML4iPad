//
//  DrawOnImageView.swift
//  DrawOnImage
//
//  Created by Bartolomeo Sorrentino on 03/02/23.
//
// Inspired by : [Background Image and canvas with pencilKit Swiftui](https://stackoverflow.com/a/69298063/521197))
//

import SwiftUI
import PencilKit
import UIKit

struct DrawOnImageView: View {

    @State private var canvasView: PKCanvasView = PKCanvasView()
    var image: UIImage?
//    @State private var drawingOnImage: UIImage = UIImage()

//    @Binding var image: UIImage
//    let onSave: (UIImage) -> Void

//    init(image: Binding<UIImage>, onSave: @escaping (UIImage) -> Void) {
//        self._image = image
//        self.onSave = onSave
//    }

    init(image: UIImage?) {
        self.image = image
    }

    var body: some View {
        if let image  {
            Image( uiImage: image )
                //.resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
                .overlay( CanvasView(canvasView: $canvasView, onSaved: onChanged), alignment: .bottomLeading )

        }
        else {
            EmptyView()
        }
    }

    private func onChanged() -> Void {
//        self.drawingOnImage = canvasView.drawing.image(
//            from: canvasView.bounds, scale: UIScreen.main.scale)
    }

//    private func initCanvas() -> Void {
//        self.canvasView = PKCanvasView();
//        self.canvasView.isOpaque = false
//        self.canvasView.backgroundColor = UIColor.clear
//        self.canvasView.becomeFirstResponder()
//    }

    private func save() -> Void {
//        onSave(self.image.mergeWith(topImage: drawingOnImage))
    }
}

struct CanvasView {
    @Binding var canvasView: PKCanvasView
    let onSaved: () -> Void

    @State var toolPicker = PKToolPicker()
}

extension CanvasView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .gray, width: 10)
        #if targetEnvironment(simulator)
        canvasView.drawingPolicy = .anyInput
        #endif
        canvasView.isOpaque = false
        canvasView.backgroundColor = UIColor.clear
        canvasView.delegate = context.coordinator
        showToolPicker()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasView: $canvasView, onSaved: onSaved)
    }
}

private extension CanvasView {
    
    func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
}

class Coordinator: NSObject {
    var canvasView: Binding<PKCanvasView>
    let onSaved: () -> Void

    init(canvasView: Binding<PKCanvasView>, onSaved: @escaping () -> Void) {
        self.canvasView = canvasView
        self.onSaved = onSaved
    }
}

extension Coordinator: PKCanvasViewDelegate {
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if !canvasView.drawing.bounds.isEmpty {
            onSaved()
        }
    }
}

//struct DrawOnImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        DrawOnImageView()
//    }
//}
