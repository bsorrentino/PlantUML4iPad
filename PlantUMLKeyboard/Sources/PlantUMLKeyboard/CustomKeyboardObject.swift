import Combine
import SwiftUI
import UIKit

public class CustomKeyboardObject : ObservableObject {
    
    @Published public var showKeyboard = false

    @Published public var itemsToAdd:[String] = []

    private var keyboardRect:CGRect = .zero
    
    private var cancellable:AnyCancellable?
    
    public init() {
       
        NotificationCenter.default.addObserver(
            
            forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { [weak self] notification in
            
                print( "keyboardDidShowNotification: \(notification)" )
                    
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

//        cancellable = _showKeyboard.projectedValue.sink { value in
//            print( "showKeyboard: \(value)" )
//
//            if( value ) {
//                self.show()
//            }
//            else {
//                self.hide()
//            }
//
//        }
        
    }
    
    //
    //[Cannot convert value of type 'Published<Bool>.Publisher' to expected argument type 'Binding<Bool>'](https://stackoverflow.com/a/63282875/521197)
    //
    private var showKeyboardBinding:Binding<Bool> {
        Binding(
            get: { [weak self] in
                (self?.showKeyboard ?? false)
            },
            set: { [weak self] in
                self?.showKeyboard = $0
            }
        )
    }
}
