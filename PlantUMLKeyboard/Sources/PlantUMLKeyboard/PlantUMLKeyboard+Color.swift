//
//  PlantUMLKeyboard+Color.swift
//  
//
//  Created by Bartolomeo Sorrentino on 05/01/23.
//

import SwiftUI

// MARK: Color extension
extension Color {
    
    typealias RGBA = (R:Int, G:Int, B:Int, A:Int )
    
    func hexValue() -> RGBA? {
        var output:RGBA? = nil
        
        if let values = self.cgColor?.components {
            
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
        
        if let rgba:RGBA = self.hexValue() {
            output = "#\(String(format:"%02X", rgba.R))\(String(format:"%02X", rgba.G))\(String(format:"%02X", rgba.B))\( String(format:"%02X", rgba.A))"
        }
        
        return output
    }
}

struct ColorKeyView: View {
    @State private var selectedColor = Color.blue.opacity(0.5)

    var symbol:Symbol
    var onPressSymbol: (Symbol) -> Void
    
    var body: some View {
        VStack {

            ColorPicker( selection: $selectedColor, label: {
                Text(symbol.id).font(.system(size: 16).bold())

            })
            .onChange(of: selectedColor ) { color in
                onPressSymbol( makeSymbol( from: color ) )
            }
        }
    }
    
    private func makeSymbol( from  color: Color ) -> Symbol {
        
        let value = String(format: symbol.value, color.hexValue() ?? "")
        return Symbol( id: symbol.id, value: value )
    }
}


//struct ColorPickerKeyView_Previews: PreviewProvider {
//    static var previews: some View {
//        ColorPickerKeyView()
//    }
//}
