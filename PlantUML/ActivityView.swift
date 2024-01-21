//
//  ActivityView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 21/01/24.
//

import SwiftUI

struct ActivityView<Content>: View where Content: View {
    @Environment( \.colorScheme) var colorScheme
    
    @Binding var isShowing: Bool
    var label: String = "Loading ..."
    var content: () -> Content
    
    private var borderColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    private var color: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)
                
                if isShowing {
                    VStack {
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke( borderColor, lineWidth: 1)
                            .frame( width: geometry.size.width * 0.6,
                                    height: geometry.size.height * 0.2)
                            .background()
                            .overlay {
                                ProgressView {
                                    VStack{
                                        Text(label)
                                            .font(.title)
                                            .foregroundColor(color)
                                    }
                                }
                                .controlSize(.large)
                                .tint(color)
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.opacity(self.isShowing ? 1 : 0)
                }
            }
        }
    }
}


#Preview {
    ActivityView(isShowing: .constant(true)) {
        
        Text( "DRAWING" )
    }
}
