import SwiftUI
import UIKit

func getFirstWindow() -> UIWindow? {
    
    let scenes = UIApplication.shared.connectedScenes
    guard let windowScene = scenes.first as? UIWindowScene else {
        return nil
    }
    guard let window = windowScene.windows.first else {
        return nil
    }
    return window

}

// https://stackoverflow.com/a/1823360/521197
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

func getFirstTextFieldResponder() -> UITextField? {
    
    let scenes = UIApplication.shared.connectedScenes
    guard let windowScene = scenes.first as? UIWindowScene else {
        return nil
    }
    guard let window = windowScene.windows.first else {
        return nil
    }
    
    guard let firstResponder = window.firstResponder else {
        return nil
    }
    
    return firstResponder as? UITextField
}

public func getRootViewController() -> UIViewController? {
    getFirstWindow()?.rootViewController
}

fileprivate var plantUMLSymbols = [
    ["actor",
    "boundary",
    "control",
    "entity",
    "database",
    "collections",
    "queue"],

]

public struct PlantUMLKeyboardView: View {
        
    @Binding var show : Bool
    @Binding var value : String
    
    public init( show: Binding<Bool>, value: Binding<String> ) {
        self._show = show
        self._value = value
    }
    
    public var body : some View{
        
        ZStack(alignment: .topLeading) {
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 5){
                    
                    ForEach(plantUMLSymbols,id: \.self) { i in
                        
                        HStack(spacing: 10){
                            
                            ForEach(i,id: \.self) { symbol in
                                
                                Button(action: {
                                    
                                    self.value = symbol
                                    
                                    print( "TextViewResponder \(String(describing: getFirstTextFieldResponder()))")
                                }) {
                                    
                                    Text(symbol)
                                        .font(.system(size: 15))
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            
            }
            .frame(
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.height / 3)
            .background(Color.white)
            .cornerRadius(25)
            
            Button(action: {
                self.show.toggle()
            }) {
                Image(systemName: "xmark").foregroundColor(.black)
            }
            .padding()
        }
    }
    
}


struct PlantUMLKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLKeyboardView( show: Binding.constant(true), value: Binding.constant("TEST"))
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
