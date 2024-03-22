//
//  XCUIElement+Gesture.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 22/03/24.
//

import XCTest

// table extension
extension XCUIElement {
    

    /// Performs a swipe left gesture on the UI element.
    ///
    /// This simulates a long swipe left gesture by calculating start and end points
    /// with normalized offsets, pressing on the start point, and dragging to the end point.
    ///
    /// Useful for navigating back or dismissing views in UI Tests.
    /// [Perform a full swipe left action in UI Tests?](https://stackoverflow.com/a/51639973)
    func longSwipeLeft() {
        let startOffset: CGVector
        let endOffset: CGVector

        startOffset = CGVector(dx: 0.6, dy: 0.0)
        endOffset = CGVector.zero

        let startPoint = self.coordinate(withNormalizedOffset: startOffset)
        let endPoint = self.coordinate(withNormalizedOffset: endOffset)
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
    }
    


}
