//
//  ScaleToFit+ToggleStyle.swift
//  PlantUML4iPad
//
//  Created by Bartolomeo Sorrentino on 10/12/22.
//
// inspired by: [Customizing Toggle with ToggleStyle](https://www.hackingwithswift.com/quick-start/swiftui/customizing-toggle-with-togglestyle)
//

import SwiftUI

struct ScaleToFitToggleStyle: ToggleStyle {
    var imageScale:Image.Scale = .medium
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ?
                        "arrow.up.left.and.arrow.down.right" :
                        "arrow.down.right.and.arrow.up.left")
//                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                    .imageScale(imageScale)
                    
            }
            .labelStyle(.iconOnly)
        }
//        .buttonStyle(PlainButtonStyle())
    }
}

struct ScaleToFitToggleStyle_Previews: PreviewProvider {
    static var previews: some View {
        
        Toggle("Fit Image", isOn: .constant(true))
            .toggleStyle(ScaleToFitToggleStyle())
    }
}
