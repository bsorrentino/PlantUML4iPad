//
//  XCTestCase+LineEditor.swift
//  PlantUMLAppUITests
//
//  Created by Bartolomeo Sorrentino on 05/04/23.
//

import XCTest

extension XCTestCase {
    
    func getCellTextField( table: XCUIElement, atRow row: Int, handler: (( XCUIElement ) -> Void)? = nil ) -> Void {
        
        XCTAssertEqual( table.elementType, XCUIElement.ElementType.table)
        XCTAssertTrue( row >= 0 && row < table.cells.count, "index: \(row) is out of bound \(table.cells.count)")
        
        let cell = table.cells.element(boundBy: row)
        XCTAssertTrue(cell.exists)
        
        let textField = cell.textFields.element(boundBy: 0 )
        XCTAssertTrue(textField.exists)
        
        handler?( textField )
        
    }

}

