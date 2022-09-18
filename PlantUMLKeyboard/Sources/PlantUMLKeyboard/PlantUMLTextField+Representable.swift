//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 18/09/22.
//

import UIKit
import SwiftUI

public struct PlantUMLTextFieldWithCustomKeyboard : UIViewRepresentable {
    
    public typealias UIViewType = UITextField

    private let textField = UITextField()
    
    public init() {
        
    }
    
    public func makeCoordinator() -> PlantUMLTextFieldWithCustomKeyboard.Coordinator {
        Coordinator(textfield: self)
    }
    
    public func makeUIView(context: Context) -> UITextField {
        
        textField.delegate = context.coordinator
        return textField
    }
    
    public func updateUIView(_ uiView: UITextField, context: Context) {
        
    }
    

    public class Coordinator: NSObject, UITextFieldDelegate {
        
        private let parent : PlantUMLTextFieldWithCustomKeyboard

        public init(textfield : PlantUMLTextFieldWithCustomKeyboard) {
          self.parent = textfield
        }

    }
    
}
