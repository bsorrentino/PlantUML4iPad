//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 18/09/22.
//

import UIKit
import SwiftUI
import PlantUMLFramework
import Combine

public enum AppendActionPosition {
    case BELOW
    case ABOVE
}

public struct PlantUMLTextFieldWithCustomKeyboard : UIViewRepresentable {
    public typealias ChangeHandler =  ( SyntaxStructure, String, [String]? ) -> Void
    public typealias AddNewActionHandler = ( SyntaxStructure, AppendActionPosition, String? ) -> Void
    public typealias UIViewType = UITextField
    private let textField = UITextField()
    
    public var item:SyntaxStructure
    public var onChange:ChangeHandler
    public var onAddNew:AddNewActionHandler

    @Binding private var showingKeyboard: Bool
    
    public init( item:SyntaxStructure,
                 showingKeyboard: Binding<Bool>,
                 onChange:@escaping ChangeHandler,
                 onAddNew:@escaping AddNewActionHandler
    ) {
        self.item = item
        self._showingKeyboard = showingKeyboard
        self.onChange = onChange
        self.onAddNew = onAddNew
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
        private var cancellable:AnyCancellable?
        private var customKeyboardMinHeight = 300.0
        
        private var keyboardRectPublisher: AnyPublisher<CGRect, Never> {
            // 2.
            let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
                .map {
                    guard let rect = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                        return CGRect.zero
                    }
                    
                    self.customKeyboardMinHeight = max( self.customKeyboardMinHeight, rect.size.height)
                    
                    return rect
                }
            
            let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
                .map { _ in CGRect.zero }
                
            // 3.
            return Publishers.MergeMany(willShow, willHide).eraseToAnyPublisher()
                    
        }

        public init(textfield : PlantUMLTextFieldWithCustomKeyboard) {
            self.owner = textfield
            self.showCustomKeyboard = false
            super.init()
            
            self.cancellable = self.keyboardRectPublisher.sink {  [weak self] rect in
                self?.keyboardRect = rect
            }

            updateAccesoryView()
            
        }
        
        func updateAccesoryView() {
            if owner.textField.inputAccessoryView == nil {

                let bar = UIToolbar()
                let toggleKeyboard = UIBarButtonItem(title: "PlantUML Keyboard", style: .plain, target: self, action: #selector(toggleCustomKeyobard))
                let addBelow = UIBarButtonItem(title: "Add Below", style: .plain, target: self, action: #selector(addBelow))
                let addAbove = UIBarButtonItem(title: "Add Above", style: .plain, target: self, action: #selector(addAbove))
                bar.items = [
                    toggleKeyboard,
                    addBelow,
                    addAbove
                ]
                bar.sizeToFit()
                owner.textField.inputAccessoryView = bar
                
            }

        }
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            if let text = textField.text, let range = Range(range, in: text) {
                owner.onChange( owner.item,
                                text.replacingCharacters(in: range, with: string),
                                nil )
            }
            
            return true
        }
        
        /// Lazy creation Input View
        var customKeyboardView:UIView {
            let keyboardView = PlantUMLKeyboardView(onHide: toggleCustomKeyobard, onPressSymbol: onPressSymbol )
            let controller = UIHostingController( rootView: keyboardView )
            
            
            var customKeyboardRect = keyboardRect
            let MAGIC_NUMBER = 50.0 // 104.0 // magic number .. height of keyboard top bar
            
            customKeyboardRect.origin.y += MAGIC_NUMBER
            customKeyboardRect.size.height = max( self.customKeyboardMinHeight, customKeyboardRect.size.height) - MAGIC_NUMBER
            controller.view.frame = customKeyboardRect
            return controller.view
     
        }
        
        @objc public func addBelow() {
            self.owner.onAddNew(owner.item, .BELOW, "")
        }
        
        @objc public func addAbove() {
            self.owner.onAddNew(owner.item, .ABOVE, "")
        }

        @objc public func toggleCustomKeyobard() {
            logger.trace( "toggleCustomKeyobard: \(self.showCustomKeyboard)" )
            
            showCustomKeyboard.toggle()
            
            if( showCustomKeyboard ) {
                owner.textField.inputView = customKeyboardView
            }
            else {
                owner.textField.inputView = nil
            }
            owner.textField.reloadInputViews()
            self.owner.showingKeyboard = showCustomKeyboard
            
        }

        func onPressSymbol(_ symbol: Symbol) {
            
            // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
            if let range = owner.textField.selectedTextRange {
                // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
                owner.textField.replace(range, withText: symbol.value )
                if let text = owner.textField.text {
                    owner.textField.sendActions(for: .valueChanged)
                    owner.onChange( owner.item, text, symbol.additionalValues )
                    toggleCustomKeyobard()
                }
            }
        }

    }

}
