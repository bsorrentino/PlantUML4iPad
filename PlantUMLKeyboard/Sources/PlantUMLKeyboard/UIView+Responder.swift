//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 13/09/22.
//

import UIKit

// [Get the current first responder without using a private API](https://stackoverflow.com/a/1823360/521197)
extension UIView {
    
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }

        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }

        return nil
    }
}

