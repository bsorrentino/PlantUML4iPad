//
//  AsyncImage+Cache.swift
//  PlantUML4iPad
//
//  Created by Bartolomeo Sorrentino on 04/12/22.
//

import SwiftUI

struct CachedAsyncImage<Content>: View where Content: View {
    
    private let url: URL
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ){
        self.url = url!
        self.scale = scale
        self.transaction = Transaction()
        self.content = content
    }
    
    var body: some View {
        
        if let cached = ImageCache[url] {
//            let _ = print("cached: \(url.absoluteString)")
            content(.success(cached))
        } else {
//            let _ = print("request: \(url.absoluteString)")
            AsyncImage(
                url: url,
                scale: scale,
                transaction: transaction,
                content: cacheAndRender
            ) 
        }
    }
    
    func cacheAndRender(phase: AsyncImagePhase) -> some View{
            if case .success (let image) = phase {
                ImageCache[url] = image
            }
            return content(phase)
        }
    
}

fileprivate class ImageCache{
    
    static private var cache: [URL: Image] = [:]
    
    static subscript(url: URL) -> Image?{
        get{
            ImageCache.cache[url]
        }
        set{
            ImageCache.cache[url] = newValue
        }
    }
}

