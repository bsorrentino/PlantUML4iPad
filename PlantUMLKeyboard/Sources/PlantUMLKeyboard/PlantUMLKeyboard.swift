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

struct Symbol : Identifiable, CustomStringConvertible {
    var description: String {
        return id
    }
    
    var id:String
    private var _value:String?
    
    var value: String {
        get { _value ?? id }
    }
    
    init( _ id:String, _ value:String? = nil) {
        self.id = id
        self._value = value
    }
}

fileprivate var plantUMLSymbols:[[Symbol]] = [
    [
        Symbol("title", "title my title"),
        Symbol("header", "header my header"),
        Symbol("footer", "footer my footer"),
        Symbol("autonumber")
    ],
    [
        Symbol("participant","participant \"my participant\" as P1"),
        Symbol("actor", "actor \"my actor\" as A1"),
        Symbol("boundary", "boundary \"my boundary\" as B1"),
        Symbol("control", "control \"my control\" as C1"),
        Symbol("entity", "entity \"my entity\" as E1"),
        Symbol("database", "database \"my database\" as DB1"),
        Symbol("collections","collections \"my collections\" as CC1" ),
        Symbol("queue", "queue \"my queue\" as Q1")
    ],
    
    [
        Symbol("->x"),
        Symbol("->"),
        Symbol("->>"),
        Symbol("-\\\\"),
        Symbol("\\\\-"),
        Symbol("//--"),
        Symbol("->o"),
        Symbol("o\\\\--"),
        Symbol("<->"),
        Symbol("<->o"),
    ],
    
    [
        Symbol("[#red]"),
        Symbol("note", "note"),
        Symbol("end note"),
    ]
    
]

fileprivate var plantUMLImages:[[UIImage?]] = {
    
    guard let arrows = UIImage(named: "plantuml-sequence-arrows")?.extractTiles( with: CGSize( width: 158.0, height: 28.6) ) else {
        return [ [], [] ,[], [] ]
    }

    return [ [], [], arrows, [] ]
}()


// [StackOverflow](https://stackoverflow.com/a/73628496/521197)
extension UIImage {

    func extractTiles(with tileSize: CGSize) -> [UIImage?] {
        
        let hCount = Int(self.size.height / tileSize.height )
        let wCount = Int(self.size.width / tileSize.width )

        var tiles:[UIImage] = []

        for i in 0...hCount-1 {
            for p in 0...wCount-1 {
                let rect = CGRect(
                    x: CGFloat(p) * tileSize.width,
                    y: CGFloat(i) * tileSize.height,
                    width: tileSize.width,
                    height: tileSize.height)
                let temp:CGImage = self.cgImage!.cropping(to: rect)!
                tiles.append(UIImage(cgImage: temp))
            }
        }
        return tiles
    }
    
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

    }
}

struct KeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(3)
            .border( .black, width: 1)
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
    static var previews: some View {
        PlantUMLKeyboardView( show: Binding.constant(true), value: Binding.constant("TEST"))
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
