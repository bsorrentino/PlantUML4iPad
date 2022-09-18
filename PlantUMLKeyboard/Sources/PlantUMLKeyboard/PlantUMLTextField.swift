//
//  PlantUMLTextField.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 06/09/22.
//

import SwiftUI

public struct PlantUMLTextField: View {
    
    public typealias ChangeHandler =  ( String ) -> Void
    
    @ObservedObject var customKeyboard: CustomKeyboardObject
    
    @State var value: String
    
    @FocusState private var isFocused: Bool
    
    var onChange:ChangeHandler
    
    public init( value: String, customKeyboard: CustomKeyboardObject, onChange:  @escaping ChangeHandler ) {
        self.value = value
        self.customKeyboard = customKeyboard
        self.onChange = onChange
    }
    
    public var body: some View {

        VStack {
            
            HStack(spacing: 15) {
                
                TextField( "", text: $value )
                    .keyboardType(.asciiCapableNumberPad)
                    .textInputAutocapitalization(.never)
                    .font(Font.system(size: 15).monospaced())
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onChange(of: value, perform: onChange )
//                    .introspectTextField { textField in
//                        print( "==> introspectTextField: \(value)" )                        
//                    }
                    
                    
                if( isFocused ) {
                    ShowKeyboardAccessoryButton( show: $customKeyboard.showKeyboard )
                }
            }
            
        }
        .edgesIgnoringSafeArea(.all)

    }
}

struct PlantUMLTextField_Previews: PreviewProvider {
            
    struct PlantUMLTextFieldProxy : View {
        @ObservedObject var customKeyboard = CustomKeyboardObject()
        
        public var body : some View {
            PlantUMLTextField(value: "test", customKeyboard: customKeyboard, onChange:  { (v) in } )
        }
    }
    
    static var previews: some View {
        PlantUMLTextFieldProxy()
    }

}
