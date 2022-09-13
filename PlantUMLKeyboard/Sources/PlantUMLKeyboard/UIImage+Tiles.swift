//
//  UIImage+Tiles.swift
//  
//
//  Created by Bartolomeo Sorrentino on 13/09/22.
//

import UIKit

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
