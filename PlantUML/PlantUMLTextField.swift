//
//  PlantUMLTextField.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 06/09/22.
//

import SwiftUI
import PlantUMLKeyboard

fileprivate struct PlantUMLTextField_old: View  {
    @State var value: String
    
    var onChange: ( String ) -> Void
    
    var body: some View {
        TextField( "", text: $value )
            .textInputAutocapitalization(.never)
            .font(Font.system(size: 15).monospaced())
            .submitLabel(.done)
            .onChange(of: value
                      , perform: onChange )

    }
    
}

struct PlantUMLTextField: View {
    @State var value: String
    @Binding var showKeyboard: Bool
    
    @FocusState private var isFocused: Bool
    
    var onChange: ( String ) -> Void
    
    
    var body: some View {

        VStack {
            
            HStack(spacing: 15){
                
                TextField( "", text: $value )
                    .textInputAutocapitalization(.never)
                    .font(Font.system(size: 15).monospaced())
                    .submitLabel(.done)
                    .focused($isFocused)
                    .onChange(of: value, perform: onChange )
                    
                    
                if( isFocused ) {
                    ShowKeyboardAccessoryButton
                }
            }
            
        }
//        .background(Color("Color")
//        .animation(.easeInOut(duration: 2), value: 1.0)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            
            // https://twitter.com/steipete/status/331774953336745985
//            NotificationCenter.default.addObserver(forName: Notification.Name("UIWindowFirstResponderDidChangeNotification"),
//                                                   object: nil,
//                                                   queue: .main) { ( object ) in
//                print( "UIWindowFirstResponderDidChangeNotification \(object)" )
//            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
                                                   object: nil,
                                                   queue: .main) { (_) in
                self.showKeyboard = false
            }
        }

    }
}

extension PlantUMLTextField {
    
    var ShowKeyboardAccessoryButton: some View {
        
            Button(action: {
                
                print( "show keyboard")
                
                if let rootViewController = getRootViewController() {
                    rootViewController.view.endEditing(true)
                }
                
                self.showKeyboard.toggle()
                
            }) {
                
                Image(systemName: "keyboard.badge.ellipsis")
                    .foregroundColor(.black.opacity(0.5))
            }
    }
}


struct PlantUMLTextField_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLTextField(value: "test", showKeyboard: .constant(false), onChange:  { (v) in } )
    }
}
