//
//  SwiftUI+PencilKit.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 29/12/23.
//

import SwiftUI
import PencilKit

class UIDrawingViewController : UIViewController, UIScrollViewDelegate {
    
    var canvas: PKCanvasView
    let scrollView = UIScrollView()
    var picker = PKToolPicker()
        
    init( initialDrawing drawing: PKDrawing ) {
        self.canvas = PKCanvasView(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        super.init(nibName: nil, bundle: nil );
        
        if DEMO_MODE {
            slowDrawingForDemo(drawing: drawing, timeInterval: 1.2)
        }
        else {
            self.canvas.drawing = drawing
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (self: Self, previousTraitCollection: UITraitCollection) in
            
            self.updateAppearance(for: self.traitCollection.userInterfaceStyle)
        }
        
        setupScrollView()
        setupCanvasView()
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.frame = view.bounds
        scrollView.backgroundColor = .gray
        view.addSubview(scrollView)
    }
    
    private func setupCanvasView() {
        picker.showsDrawingPolicyControls = false
        canvas.isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        
        updateAppearance( for: UITraitCollection.current.userInterfaceStyle )
        
        scrollView.addSubview(canvas)
        scrollView.contentSize = canvas.frame.size
    }
    
    private func updateAppearance(for userInterfaceStyle: UIUserInterfaceStyle) {
        /// [Using PencilKit in dark mode results in wrong color](https://stackoverflow.com/a/75646551/521197)
        let color = PKInkingTool.convertColor(.white, from: .light, to: .dark)
        canvas.tool = PKInkingTool(.pen, color: color)

        switch userInterfaceStyle {
         case .dark:
            canvas.backgroundColor = .black
         default:
            canvas.backgroundColor = .white
         }

    }
    
    // UIScrollViewDelegate method to enable zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvas
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        
//        // Check if the user interface style has changed
//        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
//            updateAppearance(for: traitCollection.userInterfaceStyle)
//        }
//    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        canvas.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)        
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        picker.setVisible(false, forFirstResponder: canvas)
        self.update(isUsePickerTool: false)
        
    }

    func update( isUsePickerTool: Bool ) {
        
        if( isUsePickerTool ) {
            picker.addObserver(canvas)
            picker.setVisible(true, forFirstResponder: canvas)
        }
        else {
            picker.setVisible(false, forFirstResponder: canvas)
            picker.removeObserver(canvas)
        }
    }
    
    var isScrollEnabled:Bool {
        get {
            scrollView.isScrollEnabled
        }
        set {
            scrollView.isScrollEnabled = newValue
            canvas.drawingPolicy = (newValue) ? .pencilOnly : .anyInput ;
        }
    }
    
}

// MARK: DEMO

extension UIDrawingViewController {
    
    fileprivate func slowDrawingForDemo( drawing: PKDrawing, timeInterval: TimeInterval  ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            self.canvas.drawing = PKDrawing()
            
            let strokes = drawing.strokes
            var current:Int = 0
            
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
                
                guard current < strokes.count else {
                    timer.invalidate()
                    return
                }
                let newDrawing = PKDrawing(strokes: [strokes[current]] )
                self.canvas.drawing.append(newDrawing  )
                current += 1
            }
        }
    }

}

struct DrawingView: UIViewControllerRepresentable {
    @Binding var drawing: PKDrawing
    var isUsePickerTool: Bool
    var isScrollEnabled: Bool
    
    func makeUIViewController(context: Context) -> UIDrawingViewController {
        let controller =  UIDrawingViewController( initialDrawing: drawing )
        controller.canvas.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDrawingViewController, context: Context) {
        // updating the tool whenever the view updates
        uiViewController.update(isUsePickerTool: isUsePickerTool)
        uiViewController.isScrollEnabled = isScrollEnabled
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator( owner: self )
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        
        var owner: DrawingView
        
        init(owner: DrawingView) {
            self.owner = owner
        }
        // Implement the delegate methods here
        // PKCanvasViewDelegate
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            owner.drawing = canvasView.drawing
        }
    }
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


#Preview {
    
    DrawingView( drawing: .constant(PKDrawing()),
                 isUsePickerTool: true,
                 isScrollEnabled: true)
    
    
}
