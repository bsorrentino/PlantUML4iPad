import SwiftUI
import UIKit






public struct PlantUMLKeyboardView: View {
    
    @ObservedObject var customKeyboard: CustomKeyboardObject
    
//    public init( show: Binding<Bool>, result:Binding<[String]> ) {
//        self._show = show
//        self._result = result
//    }
    
    public var body : some View{
        
        ZStack(alignment: .topLeading) {
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 15){
                    
                    ForEach( Array(plantUMLSymbols.enumerated()), id: \.offset) { rowIndex, i in
                        
                        HStack(spacing: 10) {
                            
                            ForEach( Array(i.enumerated()), id: \.offset ) { cellIndex, symbol in
                                
                                Button {
                                    
                                    replaceSymbolAtCursorPosition(symbol)
                                    
                                } label: {
                                    
                                    ButtonLabel( rowIndex: rowIndex, cellIndex: cellIndex, symbol: symbol )
                                    
                                }
                                .buttonStyle( KeyButtonStyle() )
                            }
                        }
                    }
                }
                .padding(.top)
            
            }
            .frame(maxWidth: .infinity )
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
            
            Button(action: {
                customKeyboard.showKeyboard.toggle()
            }) {
                Image(systemName: "xmark").foregroundColor(.black)
            }
            .padding()
        }
    }
    
    //
    //
    //
    func replaceSymbolAtCursorPosition( _ symbol: Symbol) {
        guard let handleToYourTextView = getFirstTextFieldResponder() else {
            return
        }
        
        print( "TextViewResponder \(handleToYourTextView)")
        
        // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
        if let range = handleToYourTextView.selectedTextRange {
            // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
            handleToYourTextView.replace(range, withText: symbol.value )
        }
        
        if let additionalValues = symbol.additionalValues {
            customKeyboard.itemsToAdd = additionalValues
        }

    }
}

struct KeyButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .border( .black, width: 1)
            .background( .white )
    }
}


extension PlantUMLKeyboardView {
    
    func ButtonLabel( rowIndex: Int, cellIndex: Int, symbol: Symbol ) -> some View  {
        
        Group {
            if plantUMLImages[rowIndex].isEmpty || plantUMLImages[rowIndex].isEmpty ||   plantUMLImages[rowIndex][cellIndex]==nil
            {
                Text(symbol.description)
                    .font(.system(size: 16).bold())

            }
            else {
                let img = plantUMLImages[rowIndex][cellIndex]
                Image( uiImage: img! )
                    .resizable()
                    .frame(width: 40, height: 20)
            }
        }
    }
}

struct PlantUMLKeyboardView_Previews: PreviewProvider {
    
    struct UserView : View {
        @ObservedObject var customKeyboard = CustomKeyboardObject()
        
        public var body : some View {
            PlantUMLKeyboardView( customKeyboard: customKeyboard )
        }
    }
    
    static var previews: some View {
        UserView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
