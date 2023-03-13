//
//  PlantUMLKeyboard+Color.swift
//  
//
//  Created by Bartolomeo Sorrentino on 05/01/23.
//

import SwiftUI
import Combine

typealias RGBA = (R:Int, G:Int, B:Int, A:Int )

// MARK: CGColor extension

extension CGColor {
    
    func rgbValue() -> RGBA? {
        var output:RGBA? = nil
        
        if let values = self.components {
            
            switch values.count {
            case 1:
                output = ( Int(values[0] * 255), Int(values[0] * 255), Int(values[0] * 255),1)
                break
            case 2:
                output = ( Int(values[0] * 255), Int(values[0] * 255), Int(values[0] * 255),Int(values[1] * 255))
                break
            case 3:
                output = ( Int(values[0] * 255), Int(values[1] * 255), Int(values[2] * 255),1)
            case 4:
                output = ( Int(values[0] * 255), Int(values[1] * 255), Int(values[2] * 255),Int(values[3] * 255))
            default:
                break
            }
        }
        
        return output
    }
    
    func hexValue() -> String? {
        var output:String? = nil
        
        if let rgba:RGBA = self.rgbValue() {
            output = "#\(String(format:"%02X", rgba.R))\(String(format:"%02X", rgba.G))\(String(format:"%02X", rgba.B))\( String(format:"%02X", rgba.A))"
        }
        
        return output
    }

}

// MARK: Color extension
extension Color {
        
    func hexValue() -> String? {
        self.cgColor?.hexValue()
    }
}

/*
struct ColorKeyButton2 : UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme

    var symbol:Symbol
    var onPressSymbol: (Symbol) -> Void
    
    init(symbol: Symbol, onPressSymbol: @escaping (Symbol) -> Void) {
        self.symbol = symbol
        self.onPressSymbol = onPressSymbol
    }

    func makeCoordinator() -> Coordinator {
        Coordinator( self )
    }
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        
        
        //
        // title
        //
        button.setTitle(symbol.id, for: .normal)
        button.layer.backgroundColor = (colorScheme == .dark) ? UIColor.black.cgColor : UIColor.white.cgColor
        
        button.setTitleColor( (colorScheme == .dark) ? UIColor.white : UIColor.black, for: .normal)
        if let label = button.titleLabel {
            label.font = (colorScheme == .dark) ?
                UIFont.systemFont(ofSize: 16, weight: .regular) :
                UIFont.systemFont(ofSize: 16, weight: .bold)
        }
        
        //
        // Image
        //
//        if let image = UIImage(named: "paintpalette", in: .module, compatibleWith: nil)  {
//            result.setImage(image, for: .normal)
//        }
        if let image = UIImage(systemName: "paintbrush.fill") {
            button.setImage(image, for: .normal)
        }
    
        //
        // Border
        //
        button.layer.borderColor = (colorScheme == .dark) ? UIColor.white.cgColor : UIColor.black.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        
        button.frame.size = CGSize(width: 100, height: 30)

        //
        // constraints
        //
//            button.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
//            button.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true

        return button
    }
    
    func updateUIView(_ button: UIButton, context: Context) {
        //
        // action
        //
        let action = UIAction(title: symbol.id ) { _ in
            
            let colorPicker = UIColorPickerViewController()
            
            colorPicker.delegate = context.coordinator
            
            getRootViewController()?.presentedViewController?.present( colorPicker,
                                                                       animated: true,
                                                                       completion: nil )
        }
    
        button.addAction( action, for: .touchDown )

    }

    

}
*/

extension ColorKeyButton {
    
    class Coordinator:  NSObject, ObservableObject, UIColorPickerViewControllerDelegate {

        @Published var selectedColor: String?
        
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            
            guard let hexColor = color.cgColor.hexValue() else {
                return
            }
                
            viewController.dismiss(animated: true, completion: nil)
            
            if( selectedColor != hexColor ) {
                selectedColor = hexColor
            }
            
        }

    }
}



struct ColorKeyButton: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var coordinator = Coordinator()

    var symbol:Symbol
    var onPressSymbol: (Symbol) -> Void
    
    init(symbol: Symbol, onPressSymbol: @escaping (Symbol) -> Void) {
        self.symbol = symbol
        self.onPressSymbol = onPressSymbol
        
    }

    private func presentViewOnRootController<T : UIViewController>( _ controller: T ) {
        getRootViewController()?.presentedViewController?.present(
            controller,
            animated: true,
            completion: nil )

    }
    var body: some View {
        Button {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = coordinator
            presentViewOnRootController( colorPicker  )
        }
        label: {
            Label(symbol.id, systemImage: "paintbrush.fill")
                .font( (colorScheme == .dark) ? .system(size: 16) : .system(size: 16).bold() )
        }
        .buttonStyle( TextKeyButtonStyle() )
        .onReceive(coordinator.$selectedColor ) { color in
            if let color {
                print( Self.self, "onReceive", color)
                
                let value = String(format: symbol.value, color )
                
                let symbol = Symbol( id: symbol.id, value: value )
                
                onPressSymbol( symbol )
            }
        }
    }
}

// MARK: Preview
struct ColorKeyButton_Previews: PreviewProvider {
    static var previews: some View {
        
        ForEach(ColorScheme.allCases, id: \.self) {
            VStack {

                ColorKeyButton( symbol:Symbol( id: "test" ), onPressSymbol: { _ in } )
                    .frame( width: 130, height: 60)
                
            }
            .preferredColorScheme($0)
        }
    }
}
