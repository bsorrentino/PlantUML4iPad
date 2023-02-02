//
//  Canvas1ViewController.swift
//  PKCanvasViewTester
//
//  Created by Kaz Yoshikawa on 5/9/20.
//  Copyright © 2020 Kaz Yoshikawa. All rights reserved.
//

import UIKit
import PencilKit


class Canvas1ViewController: UIViewController {
	
	@IBOutlet weak var canvasView: PKCanvasView!
	@IBOutlet weak var underlayView: UIImageView!

	lazy var image: UIImage = {
//		UIImage(named: "001")!
        UIImage(named: "diagram1")!
	}()

	override func viewDidLoad() {
		assert(self.canvasView != nil)
		assert(self.underlayView != nil)
		assert(self.underlayView.superview == self.canvasView)
		super.viewDidLoad()

		let image = self.image

		self.canvasView.translatesAutoresizingMaskIntoConstraints = false
		self.canvasView.contentInsetAdjustmentBehavior = .never
		self.canvasView.layer.borderColor = UIColor.red.cgColor
		self.canvasView.layer.borderWidth = 2.0
		self.canvasView.delegate = self
		self.canvasView.maximumZoomScale = 2.0
		self.canvasView.isOpaque = false
		self.canvasView.backgroundColor = .clear
		self.canvasView.contentOffset = CGPoint.zero
		self.canvasView.contentSize = image.size

		self.underlayView.contentMode = .scaleToFill
		self.underlayView.frame = CGRect(origin: CGPoint.zero, size: image.size)
		self.underlayView.image = image
		self.underlayView.layer.borderColor = UIColor.orange.cgColor
		self.underlayView.layer.borderWidth = 1.0

		if let window = UIApplication.shared.windows.first, let toolPicker = PKToolPicker.shared(for: window) {
			toolPicker.setVisible(true, forFirstResponder: self.canvasView)
			toolPicker.addObserver(self.canvasView)
			toolPicker.addObserver(self)
			self.canvasView.becomeFirstResponder()
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.canvasView.sendSubviewToBack(self.underlayView)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.canvasView.becomeFirstResponder()
		self.canvasView.tool = PKInkingTool(.pen)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		
		let contentSize = self.image.size
		self.canvasView.contentSize = contentSize
		self.underlayView.frame = CGRect(origin: CGPoint.zero, size: contentSize)
		let margin = (self.canvasView.bounds.size - contentSize) * 0.5
		let insets = [margin.width, margin.height].map { $0 > 0 ? $0 : 0 }
		self.canvasView.contentInset = UIEdgeInsets(top: insets[1], left: insets[0], bottom: insets[1], right: insets[0])
	}
	
}

extension Canvas1ViewController: PKCanvasViewDelegate {

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		self.underlayView
	}

	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		switch scrollView {
		case canvasView:
			print(Self.self, #function)
			// https://stackoom.com/question/3pNGe/%E5%A6%82%E4%BD%95%E5%B0%86UIImage%E8%BD%AC%E6%8D%A2%E6%88%96%E5%8A%A0%E8%BD%BD%E5%88%B0PKDrawing%E4%B8%AD
			let offsetX: CGFloat = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0)
			let offsetY: CGFloat = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0)
//			self.underlayView.frame.size = CGSize(width: self.view.bounds.width * scrollView.zoomScale, height: self.view.bounds.height * scrollView.zoomScale)
			self.underlayView.frame.size = self.image.size * self.canvasView.zoomScale
			self.underlayView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
		default:
			break
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		switch scrollView {
		case canvasView:
			print(Self.self, #function)
		default:
			break
		}
	}

}

extension Canvas1ViewController: PKToolPickerObserver {

	func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
		print(Self.self, #function)
	}

	func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {
		print(Self.self, #function)
	}

	func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
		print(Self.self, #function)
	}

	func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
		print(Self.self, #function)
	}

}

