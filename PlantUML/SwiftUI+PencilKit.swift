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
    let contentView = UIView()
    let backgroundImageView = UIImageView()
    var resultImage: UIImage? {
        
        // Merge backgroundImage and the current drawing, preserving the original aspect ratio
        // of the background image the same way it's displayed (aspect fit) inside the canvas.
        let canvasSize = canvas.bounds.size

        // If there's no background image, just return the drawing as-is
        let drawingUIImage = canvas.drawing.image(from: canvas.bounds, scale: 0) // 0 -> device scale
        guard let bgImage = self.backgroundImageView.image else {
            return drawingUIImage
        }

        // scoped function
        func aspectFitRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
            let imageAspect = imageSize.width / imageSize.height
            let rectAspect = rect.width / rect.height
            var result = rect
            if imageAspect > rectAspect {
                // Image is wider than rect
                let height = rect.width / imageAspect
                result.origin.y += (rect.height - height) / 2.0
                result.size = CGSize(width: rect.width, height: height)
            } else {
                // Image is taller than rect
                let width = rect.height * imageAspect
                result.origin.x += (rect.width - width) / 2.0
                result.size = CGSize(width: width, height: rect.height)
            }
            return result.integral
        }

        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        let bgTargetRect = aspectFitRect(imageSize: bgImage.size, in: canvasRect)

        // Render transparent, device scale
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let merged = renderer.image { context in
            let ctx = context.cgContext
            
            // Fill with canvas background color (use white if clear)
            let bgColor = (canvas.backgroundColor ?? .white)
            ctx.setFillColor(bgColor.cgColor)
            ctx.fill(canvasRect)
            
            // Draw the background image aspect-fitted inside the canvas
            bgImage.draw(in: bgTargetRect)
            
            // Draw the drawing (it already matches the canvas coordinate space)
            drawingUIImage.draw(in: canvasRect, blendMode: .normal, alpha: 1.0)
        }
        return merged
    }
    
    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
            // Update canvas background when an image is set/removed
            self.updateAppearance(for: self.traitCollection.userInterfaceStyle)
            
        }
    }
    var picker = PKToolPicker()
        
    init( initialDrawing drawing: PKDrawing, canvasSize: CGSize ) {
        self.canvas = PKCanvasView(frame: CGRect( origin: CGPoint(x: 0, y: 0), size: canvasSize))
        // contentView has same size as the canvas and will host backgroundImageView + canvas
        self.contentView.frame = self.canvas.frame
        
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
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
                (self: Self, previousTraitCollection: UITraitCollection) in

                self.updateAppearance(for: self.traitCollection.userInterfaceStyle)
            }
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
        #if targetEnvironment(simulator)
        canvas.drawingPolicy = .anyInput
        #else
        canvas.drawingPolicy = .pencilOnly
        #endif
        updateAppearance( for: UITraitCollection.current.userInterfaceStyle )
        
        // Prepare background image view (behind the canvas)
        backgroundImageView.frame = canvas.bounds
        backgroundImageView.contentMode = .scaleAspectFit
        //backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //backgroundImageView.contentMode = .scaleAspectFit
        backgroundImageView.image = backgroundImage

        // contentView hosts both the background image and the canvas
        //contentView.frame = canvas.frame
        contentView.addSubview(backgroundImageView)
        contentView.addSubview(canvas)

        // Add the container to the scroll view
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
    }
    
    private func updateAppearance(for userInterfaceStyle: UIUserInterfaceStyle) {
        /// [Using PencilKit in dark mode results in wrong color](https://stackoverflow.com/a/75646551/521197)
        let color = PKInkingTool.convertColor(.white, from: .light, to: .dark)
        canvas.tool = PKInkingTool(.pen, color: color)

        if backgroundImageView.image != nil {
            // When an image is set, let it show through the canvas
            canvas.backgroundColor = .clear
        } else {
            switch userInterfaceStyle {
            case .dark:
                canvas.backgroundColor = .black
            default:
                canvas.backgroundColor = .white
            }
        }
    }
    
    // UIScrollViewDelegate method to enable zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
   
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17 {
            // Check if the user interface style has changed
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance(for: traitCollection.userInterfaceStyle)
            }
        }
    }

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
    @ObservedObject var document: PlantUMLObservableDocument
    var canvasSize: CGSize = CGSize( width: 2000,height: 2000 )
    var isUsePickerTool: Bool
    var isScrollEnabled: Bool
    var requestImage: Bool
    @Binding var resultImage: UIImage?
    
    
    func makeUIViewController(context: Context) -> UIDrawingViewController {
        let controller =  UIDrawingViewController( initialDrawing: document.drawing, canvasSize: canvasSize )
        controller.canvas.delegate = context.coordinator
        controller.backgroundImage = document.drawingBackgroundImage
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDrawingViewController, context: Context) {
        // updating the tool whenever the view updates
        uiViewController.update(isUsePickerTool: isUsePickerTool)
        uiViewController.isScrollEnabled = isScrollEnabled
        uiViewController.backgroundImage = document.drawingBackgroundImage
        if requestImage {
            resultImage = uiViewController.resultImage
        }

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
            owner.document.drawing = canvasView.drawing
            
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
/*
    DrawingView( drawing: .constant(PKDrawing()),
                 isUsePickerTool: true,
                 isScrollEnabled: false,
                 backgroundImage: UIImage(named: "diagram"))
*/
    
}
