//
//  XCUIApplication+Coordinate.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 22/03/24.
//

import XCTest

extension XCUIApplication {
    /// Taps on the screen coordinate specified by point.
    ///
    /// - Parameter point: The point on the screen to tap.
    ///
    /// This converts the point to a normalized coordinate using the receiver's frame.
    /// It then applies the offset and performs the tap on the resulting coordinate.
    func tapCoordinate(dx: CGFloat, dy: CGFloat) {
        let normalized = self.coordinate(withNormalizedOffset: .zero)
        let offset = CGVector(dx: dx, dy: dy)
        let coordinate = normalized.withOffset(offset)
        coordinate.tap()
    }
}

