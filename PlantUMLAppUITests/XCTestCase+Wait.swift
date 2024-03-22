//
//  XCTestCase+Wait.swift
//  PlantUMLAppUITests
//
//  Created by bsorrentino on 22/03/24.
//

import XCTest

extension XCTestCase {
    
    func waitForNotExistence( element: XCUIElement, timeout: TimeInterval ) {
        let predicate = NSPredicate(format: "exists == FALSE")

        expectation(for: predicate, evaluatedWith: element, handler: nil)

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func waitUntilEnabled( element: XCUIElement, timeout: TimeInterval ) {
        let predicate = NSPredicate(format: "enabled == TRUE")

        let _ = XCTWaiter.wait( for: [ expectation(for: predicate, evaluatedWith: element, handler: nil) ], timeout: timeout )

    }
    
    func wait( reason description: String, timeout: TimeInterval ) {
        let _ = XCTWaiter.wait( for: [ expectation(description: description) ], timeout: timeout )
    }

}


