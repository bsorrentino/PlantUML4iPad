//
//  View+UIImage.swift
//  PlantUMLUITests
//
//  Created by Bartolomeo Sorrentino on 23/12/22.
//
//  inspired by @ref https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image
//

import SwiftUI

extension View {
    
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        guard let view = controller.view else {
            return nil
        }

        let targetSize = controller.view.intrinsicContentSize
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
