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


class DrawingUIViewController : UIViewController, UIScrollViewDelegate, PKCanvasViewDelegate {
    
    var canvas: PKCanvasView
    let scrollView = UIScrollView()
    var picker = PKToolPicker()
    var data: Data?
    
    init(_ canvas: PKCanvasView, drawingData data: Data?) {
        self.canvas = canvas
        self.data = data
        super.init(nibName: nil, bundle: nil );
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        canvas.tool = PKInkingTool(.pen, color: UIColor(.black))
        canvas.delegate = self
        canvas.backgroundColor = .white
        scrollView.addSubview(canvas)
        scrollView.contentSize = canvas.frame.size
    }
    
    private func setupDrawing() {
        
        guard let data else {
            return
        }
        
        do {
            
            let drawing = try PKDrawing(data: data)
            
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
    
    // UIScrollViewDelegate method to enable zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvas
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //             toolPicker.setVisible(true, forFirstResponder: canvas)
        //             toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        setupDrawing()
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
struct DrawingView: UIViewControllerRepresentable {
    
    @Binding var canvas: PKCanvasView
    var isUsePickerTool: Bool
    var isScrollEnabled: Bool
    var data: Data?
    
    func makeUIViewController(context: Context) -> DrawingUIViewController {
        return DrawingUIViewController( canvas, drawingData: data )
        
    }
    
    func updateUIViewController(_ uiViewController: DrawingUIViewController, context: Context) {
        // updating the tool whenever the view updates
        uiViewController.update(isUsePickerTool: isUsePickerTool)
        uiViewController.isScrollEnabled = isScrollEnabled
        
    }
    
    
    
}

struct DrawingViewDeprecated: UIViewRepresentable {
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
        
        canvas.isOpaque = false
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


#Preview {
    
    DrawingView( canvas: .constant(PKCanvasView(frame: CGRect(x: 0, y: 0, width: 2000, height: 2000))),
                 isUsePickerTool: true,
                 isScrollEnabled: true)
    
    
}
