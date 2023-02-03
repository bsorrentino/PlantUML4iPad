//
//  ContentView.swift
//  DrawOnImage
//
//  Created by Bartolomeo Sorrentino on 03/02/23.
//

import SwiftUI

struct ContentView: View {
    
    var image: UIImage?
    
    var body: some View {
        ScrollView {
            DrawOnImageView( image: image )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach( ["001a", "diagram1"], id: \.self ) { imgName in
            Group {
                ContentView( image: UIImage( named: imgName ))
                    .previewInterfaceOrientation(.portrait)
                ContentView( image: UIImage( named: imgName ) )
                    .previewInterfaceOrientation(.landscapeLeft)
            }
        }
    }
}
