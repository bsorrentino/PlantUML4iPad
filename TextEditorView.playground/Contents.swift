//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

import UIKit

class LineNumberedTextView: UITextView {
    private let lineNumberLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .lightGray
        label.textColor = .darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLineNumberLabel()
    }
    
    private func updateLineNumberLabel() {
        let layoutManager = self.layoutManager
        let textContainer = self.textContainer
        let textStorage = self.textStorage
        
        let visibleRect = self.bounds
        let visibleRange = layoutManager.characterRange(forGlyphRange: layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer), actualGlyphRange: nil)
        
        let firstVisibleGlyphCharacterIndex = visibleRange.location
        let lastVisibleGlyphCharacterIndex = NSMaxRange(visibleRange)
        
        var lineNumberRect = CGRect.zero
        layoutManager.enumerateLineFragments(forGlyphRange: visibleRange) { (rect, usedRect, textContainer, glyphRange, stop) in
            let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let lineText = (self.text as NSString).substring(with: characterRange)
            let lineNumber = 1 // layoutManager.lineNumber(for: glyphRange)
            
            let lineNumberGlyphRange = layoutManager.glyphRange(
                forCharacterRange: characterRange,
                actualCharacterRange: nil)
            let lineNumberRect = layoutManager.boundingRect(forGlyphRange: lineNumberGlyphRange, in: textContainer)
            let lineNumberLabelRect = CGRect(x: 0, y: lineNumberRect.origin.y, width: 30, height: lineNumberRect.size.height)
            
            if let lineNumberLabel = self.lineNumberLabel.copy() as? UILabel {
                lineNumberLabel.text = "\(lineNumber)"
                lineNumberLabel.frame = lineNumberLabelRect
                self.addSubview(lineNumberLabel)
            }
            
        }
    }
}

class MyViewController : UIViewController {
    
    override func loadView() {
        
        let v = LineNumberedTextView()
        v.backgroundColor = .white
        v.text = "Hello\nWorld\nLine\nNumbers"
        view = v
    }
    
    override func viewDidLoad() {
        
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
