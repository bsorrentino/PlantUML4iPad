//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Temiloluwa on 06/10/2020.
//

import XCTest
import OpenAI


class Tests_iOS: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    struct VisioMessageContent : Codable {
        var type: String
        var text: String?
        var image_url: [ String: String ]?
        
        init( url: String ) {
            type = "image_url"
            image_url = [ "url": url ]
        }

        init( text: String ) {
            type = "text"
            self.text = text
        }
    }

    func encodeToString<T : Encodable>( _ schema:T ) throws -> String? {
        let jsonData = try JSONEncoder().encode(schema)
        return String(data: jsonData, encoding: .utf8)
    }
    
    func testVision() async throws {
        
        let prompt =
        """
        Translate diagram in image in a plantUML script following rules below:

        1. every rectangle or icon must be translate in plantuml rectangle element with related label if any
        2. every rectangle that contains other elements must be translated in plantuml rectangle {}  element
        
        result must only be the plantuml script whitout any other comment
        """
        
        let imageUrl = "https://res.cloudinary.com/practicaldev/image/fetch/s--B-s5n03y--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_800/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/bm8v47dhrqxagsd615q1.png"
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_KEY"]
        
        let openai = OpenAI(apiToken: apiKey!)
            
        let query = ChatQuery(
            model: .gpt4_vision_preview,
            messages: [
                Chat(role: .user, content: [
                    ChatContent(text: prompt),
                    ChatContent(imageUrl: imageUrl)
                ])
            ],
            maxTokens: 2000
        )
        
        let result = try await openai.chats(query: query)
        
        print( result.choices[0].message )
        
    }

}
