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

public func getRootViewController() -> UIViewController? {
    getFirstWindow()?.rootViewController
}


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
                
                VStack(spacing: 15){
                    
                    ForEach(self.getEmojiList(),id: \.self){i in
                        
                        HStack(spacing: 25){
                            
                            ForEach(i,id: \.self){j in
                                
                                Button(action: {
                                    
                                    self.value += String(UnicodeScalar(j)!)
                                    
                                }) {
                                    
                                    if (UnicodeScalar(j)?.properties.isEmoji)!{
                                        
                                        Text(String(UnicodeScalar(j)!)).font(.system(size: 55))
                                    }
                                    else{
                                        
                                        Text("")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 3)
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
    
    func getEmojiList()->[[Int]]{
        
        var emojis : [[Int]] = []
        
        for i in stride(from: 0x1F601, to: 0x1F64F, by: 4){
            
            var temp : [Int] = []
            
            for j in i...i+3{
                
                temp.append(j)
            }
            
            emojis.append(temp)
        }
        
        return emojis
    }
}


struct PlantUMLKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        PlantUMLKeyboardView( show: Binding.constant(true), value: Binding.constant("TEST"))
    }
}
