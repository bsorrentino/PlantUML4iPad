//
//  View+Secure.swift
//  PlantUMLApp
//
//  Created by Bartolomeo Sorrentino on 16/05/23.
//

import SwiftUI
import PlantUMLFramework

extension String {
    // [How to remove all the spaces in a String?](https://stackoverflow.com/a/34940120/521197)
    func trimAll() -> String {
        self.filter { !$0.isWhitespace }
    }
}

public struct SecureToggleField : View {
    
    var title:String
    @Binding var value:String
    var hidden:Bool
    
    public init( _ title: String, value: Binding<String>, hidden: Bool ) {
        self.title = title
        self._value = value
        self.hidden = hidden
    }
    
    public var body: some View {
        Group {
            if( hidden ) {
                SecureField( title, text:$value)
                    .accessibilityIdentifier( "secure_toggle_field_\(title.trimAll().lowercased())")
            }
            else {
                TextField( title, text:$value)
                    .accessibilityIdentifier( "secure_toggle_field_\(title.trimAll().lowercased())" )
            }
        }
    }
}


public struct HideToggleButton : View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @Binding var hidden:Bool
    
    public init( hidden: Binding<Bool> ) {
        self._hidden = hidden
    }

    public var body: some View {
        Button( action: {
            self.hidden.toggle()
         }) {
            Group {
                if( self.hidden ) {
                    Image( systemName: "eye.slash")
                }
                else {
                    Image( systemName: "eye")
                }
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
         }
         .buttonStyle(PlainButtonStyle())

    }
}


struct View_Secure_Previews: PreviewProvider {
    
    struct PasswordField : View {
        @State var hidden = true
        var body: some View {
            HStack(spacing: 5) {
                SecureToggleField( "give me password", value: .constant("test"), hidden: hidden)
                    .fixedSize()
                    .border(.green)
                HideToggleButton( hidden: $hidden )
            }
        }
        
    }
    static var previews: some View {

        PasswordField()

    }
}

