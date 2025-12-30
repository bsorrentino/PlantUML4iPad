//
//  AgentExecutorTests.swift
//  
//
//  Created by bsorrentino on 13/03/24.
//

import XCTest
@testable import AIAgent


final class AgentExecutorTests : XCTestCase {
    
    
    func testLoadPrompt() async throws {
        let describe = try loadPromptFromBundle( fileName: "describe_diagram_prompt" )
        
        XCTAssertNotNil(describe)
        
        print( describe )
        
        let generic = try loadPromptFromBundle( fileName: "generic_diagram_prompt" )
        
        XCTAssertNotNil(generic)
        
        print( generic )
        
        let sequence = try loadPromptFromBundle( fileName: "sequence_diagram_prompt" )
        
        XCTAssertNotNil(sequence)
        
        print( sequence )

        let usecase = try loadPromptFromBundle( fileName: "usecase_diagram_prompt" )
        
        XCTAssertNotNil(usecase)
        
        print( usecase )
    }
    
    func testParseDiagramDescriptionOutput() async throws {
        
        let output =
"""
{
    "type": "process",
    "title": "LLM Application Data Flow",
    "participants": [
        { "name": "Event Stream", "shape": "cylinder", "description": "Source of event data" },
        { "name": "Preprocessing", "shape": "rectangle", "description": "Initial processing of events" },
        { "name": "LLM Application", "shape": "rectangle", "description": "Main application processing events" },
        { "name": "Postprocessing", "shape": "rectangle", "description": "Processing after main application" },
        { "name": "Output", "shape": "cylinder", "description": "Final output of the data flow" },
        { "name": "Observability", "shape": "rectangle", "description": "Metrics and logs monitoring" },
        { "name": "LLM Service", "shape": "rectangle", "description": "External service for LLM (e.g., OpenAI)" },
        { "name": "LLM Tracing", "shape": "rectangle", "description": "Tracing service for LLM (e.g., LangSmith)" }
    ],
    "relations": [
        { "source": "Event Stream", "target": "Preprocessing", "description": "Feeds into" },
        { "source": "Preprocessing", "target": "LLM Application", "description": "Feeds into" },
        { "source": "LLM Application", "target": "Postprocessing", "description": "Feeds into" },
        { "source": "Postprocessing", "target": "Output", "description": "Feeds into" },
        { "source": "LLM Application", "target": "Observability", "description": "Sends data to" },
        { "source": "LLM Application", "target": "LLM Service", "description": "Interacts with" },
        { "source": "LLM Application", "target": "LLM Tracing", "description": "Interacts with" }
    ],
    "groups": [
        {   "name": "Stream Processor", 
            "children": ["Preprocessing", "LLM Application", "Postprocessing"], 
            "description": "Processes the event stream" 
        }
    ],
    "description": [
        "The Event Stream is the starting point, which feeds into Preprocessing.",
        "Preprocessing is part of the Stream Processor and prepares data for the LLM Application.",
        "The LLM Application processes the data and may interact with external services like LLM Service and LLM Tracing.",
        "After processing, the data is sent to Postprocessing, which is also part of the Stream Processor.",
        "The Postprocessing stage prepares the final Output.",
        "Throughout the process, the LLM Application sends data to Observability for monitoring purposes."
    ]
}
"""
        
        let diagram = try diagramDescriptionOutputParse( output )
        
        XCTAssertNotNil(diagram)
        XCTAssertEqual("process", diagram.type, "Type are different!")
        XCTAssertEqual("LLM Application Data Flow", diagram.title, "Title are different!")
        
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(diagram)
        
        let content = String(data: data, encoding: .utf8)
        
        XCTAssertNotNil(content, "data conversion error!")
        
        print( "===> OUTPUT ")
        print( content! )
    }
    
    func _testParseDiagramDescriptionOutputWithComment() async throws {
        
        let output =
"""
The image contains a hand-drawn flowchart with four distinct shapes connected by arrows. Here\'s the flowchart translated into the provided diagram-as-code syntax in JSON format:\n\n```json\n{\n    \"type\": \"process\",\n    \"title\": \"Flowchart for Selecting a Diagram Type\",\n    \"participants\": [\n        { \"name\": \"DescribeDiagram\", \"shape\": \"rectangle\", \"description\": \"Box labeled DESCRIBE DIAGRAM\" },\n        { \"name\": \"ChooseType\", \"shape\": \"rectangle\", \"description\": \"Box labeled CHOOSE TYPE\" },\n        { \"name\": \"Sequence\", \"shape\": \"rectangle\", \"description\": \"Box labeled SEQUENCE\" },\n        { \"name\": \"Generic\", \"shape\": \"rectangle\", \"description\": \"Box labeled GENERIC\" },\n        { \"name\": \"Stop\", \"shape\": \"ellipse\", \"description\": \"Ellipse labeled STOP\" }\n    ],\n    \"relations\": [\n        { \"source\": \"DescribeDiagram\", \"target\": \"ChooseType\", \"description\": \"Arrow from DESCRIBE DIAGRAM to CHOOSE TYPE\" },\n        { \"source\": \"ChooseType\", \"target\": \"Sequence\", \"description\": \"Arrow from CHOOSE TYPE to SEQUENCE\" },\n        { \"source\": \"ChooseType\", \"target\": \"Generic\", \"description\": \"Arrow from CHOOSE TYPE to GENERIC\" },\n        { \"source\": \"Sequence\", \"target\": \"Stop\", \"description\": \"Arrow from SEQUENCE to STOP\" },\n        { \"source\": \"Generic\", \"target\": \"Stop\", \"description\": \"Arrow from GENERIC to STOP\" }\n    ],\n    \"containers\": [],\n    \"description\": [\n        \"Step 1: Start at the \'DESCRIBE DIAGRAM\' rectangle.\",\n        \"Step 2: Move down to the \'CHOOSE TYPE\' rectangle.\",\n        \"Step 3: From \'CHOOSE TYPE\', two options diverge, leading either left to \'SEQUENCE\' or right to \'GENERIC\'.\",\n        \"Step 4: Both \'SEQUENCE\' and \'GENERIC\' point to the \'STOP\' ellipse.\"\n    ]\n}\n```\n\nPlease, ensure to use the correct terms and formatting when you convert this JSON representation back to diagram-as-code syntax as per the requirements of the tool or language you are using.
"""
        
        let diagram = try diagramDescriptionOutputParse( output )
        
        XCTAssertNotNil(diagram)
        XCTAssertEqual("process", diagram.type, "Type are different!")
        XCTAssertEqual("Flowchart for Selecting a Diagram Type", diagram.title, "Title are different!")
        
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(diagram)
        
        let content = String(data: data, encoding: .utf8)
        
        XCTAssertNotNil(content, "data conversion error!")
        
        print( "===> OUTPUT ")
        print( content! )
    }

    func testCodableDiagramDescriptionOutput() async throws {
        
        let diagram =
"""
{\n  \"type\": \"flowchart\",\n  \"title\": \"Diagram Translation Process\",\n  \"participants\": [\n    { \"name\": \"Describe Diagram\", \"shape\": \"rectangle\", \"description\": \"Initial step to describe the diagram\" },\n    { \"name\": \"Check Type\", \"shape\": \"rectangle\", \"description\": \"Check the type of diagram\" },\n    { \"name\": \"Sequence\", \"shape\": \"rectangle\", \"description\": \"Option for a sequence diagram\" },\n    { \"name\": \"Generic\", \"shape\": \"rectangle\", \"description\": \"Option for a generic diagram\" },\n    { \"name\": \"PlantUML Sequence\", \"shape\": \"rectangle\", \"description\": \"Command to generate a sequence diagram with PlantUML\" },\n    { \"name\": \"PlantUML Generic\", \"shape\": \"rectangle\", \"description\": \"Command to generate a generic diagram with PlantUML\" },\n    { \"name\": \"Stop\", \"shape\": \"ellipse\", \"description\": \"End of process\" }\n  ],\n  \"relations\": [\n    { \"source\": \"Describe Diagram\", \"target\": \"Check Type\", \"description\": \"Leads to checking the diagram type\" },\n    { \"source\": \"Check Type\", \"target\": \"Sequence\", \"description\": \"Option selected for sequence diagrams\" },\n    { \"source\": \"Check Type\", \"target\": \"Generic\", \"description\": \"Option selected for generic diagrams\" },\n    { \"source\": \"Sequence\", \"target\": \"PlantUML Sequence\", \"description\": \"Leads to PlantUML sequence diagram creation\" },\n    { \"source\": \"Generic\", \"target\": \"PlantUML Generic\", \"description\": \"Leads to PlantUML generic diagram creation\" },\n    { \"source\": \"PlantUML Sequence\", \"target\": \"Stop\", \"description\": \"Ends the sequence diagram process\" },\n    { \"source\": \"PlantUML Generic\", \"target\": \"Stop\", \"description\": \"Ends the generic diagram process\" }\n  ],\n  \"containers\": [],\n  \"description\": \"The flowchart initiates with \'Describe Diagram\', followed by \'Check Type\' to determine if the diagram is a \'Sequence\' or \'Generic\' diagram. According to the type, it either proceeds to \'PlantUML Sequence\' or \'PlantUML Generic\' for execution. The process concludes at the \'Stop\' step.\"\n}"
"""
        
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(diagram)
        
        let content = String(data: data, encoding: .utf8)
        
        XCTAssertNotNil(content, "data conversion error!")
        
        print( "===> OUTPUT ")
        print( content! )
    }
}
