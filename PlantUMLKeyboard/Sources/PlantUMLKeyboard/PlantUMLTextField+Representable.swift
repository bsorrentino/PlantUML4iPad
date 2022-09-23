//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 18/09/22.
//

import UIKit
import SwiftUI
import PlantUMLFramework

public struct PlantUMLTextFieldWithCustomKeyboard : UIViewRepresentable {
    public typealias ChangeHandler =  ( String, [String]? ) -> Void
    public typealias UIViewType = UITextField
    private let textField = UITextField()
    
    
    public var item:SyntaxStructure
    public var onChange:ChangeHandler
    
    public init( item:SyntaxStructure, onChange:@escaping ChangeHandler ) {
        self.item = item
        self.onChange = onChange
    }
    
    public func makeCoordinator() -> PlantUMLTextFieldWithCustomKeyboard.Coordinator {
        Coordinator(textfield: self)
    }
    
    public func makeUIView(context: Context) -> UITextField {
        
        textField.delegate = context.coordinator
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textField.returnKeyType = .done
        textField.text = item.rawValue
        return textField
    }
    
    public func updateUIView(_ uiView: UITextField, context: Context) {
        
        context.coordinator.updateAccesoryView()
        
    }
}


// MARK: - CustomKeyboardPresenter protocol
protocol CustomKeyboardPresenter {
    
    func toggleCustomKeyobard() -> Void
    
    func onPressSymbol( _ symbol: Symbol ) -> Void
    
}

// MARK: - Coordinator extension
extension PlantUMLTextFieldWithCustomKeyboard {
    
    public class Coordinator: NSObject, UITextFieldDelegate, CustomKeyboardPresenter {
        
        
        private var keyboardRect:CGRect = .zero
        private let owner : PlantUMLTextFieldWithCustomKeyboard
        private var showCustomKeyboard:Bool
        
        public init(textfield : PlantUMLTextFieldWithCustomKeyboard) {
            self.owner = textfield
            self.showCustomKeyboard = false
            super.init()
            
            updateAccesoryView()
            
            NotificationCenter.default.addObserver(
                
                forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] notification in
                
                    print( "keyboardDidShowNotification" )
                        
                    if let keyboardFrameEndUser = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue) {
                            
                        print( "keyboardFrameEndUser pos=\(keyboardFrameEndUser)")

                        self?.keyboardRect = keyboardFrameEndUser.cgRectValue
                    }
                    
            }

            NotificationCenter.default.addObserver(
                
                forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] _ in
                
                    print( "keyboardDidHideNotification" )

                    self?.keyboardRect = .zero

                }


        }
        
        func updateAccesoryView() {
            if owner.textField.inputAccessoryView == nil {

                let bar = UIToolbar()
                let toggleKeyboard = UIBarButtonItem(title: "PlantUML Keyboard", style: .plain, target: self, action: #selector(toggleCustomKeyobard))
                bar.items = [
                    toggleKeyboard
                ]
                bar.sizeToFit()
                owner.textField.inputAccessoryView = bar

            }

        }
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            // print( "shouldChangeCharactersIn",  range, string )
            if let text = textField.text, let range = Range(range, in: text) {
                owner.onChange( text.replacingCharacters(in: range, with: string), nil )
            }
            
            return true
        }
        
        /// Lazy creation Input View
        var customKeyboardView:UIView {
            let keyboardView = PlantUMLKeyboardView(onHide: toggleCustomKeyobard, onPressSymbol: onPressSymbol )
            let controller = UIHostingController( rootView: keyboardView )
            
            var customKeyboardRect = keyboardRect
            let MAGIC_NUMBER = 100.0 // 50.0 // magic number .. height of keyboard top bar
            customKeyboardRect.origin.y += MAGIC_NUMBER
            customKeyboardRect.size.height -= MAGIC_NUMBER
            controller.view.frame = customKeyboardRect
            return controller.view
     
        }

        @objc public func toggleCustomKeyobard() {
            print("toggleCustomKeyobard:",  showCustomKeyboard)
            
            showCustomKeyboard.toggle()
            
            if( showCustomKeyboard ) {
                owner.textField.inputView = customKeyboardView
            }
            else {
                owner.textField.inputView = nil
            }
            owner.textField.reloadInputViews()
            
        }

        func onPressSymbol(_ symbol: Symbol) {
            
            // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
            if let range = owner.textField.selectedTextRange {
                // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
                owner.textField.replace(range, withText: symbol.value )
                if let text = owner.textField.text {
                    owner.textField.sendActions(for: .valueChanged)
                    owner.onChange( text, symbol.additionalValues )
                }
            }
        }

    }

}
