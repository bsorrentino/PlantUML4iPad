import XCTest
@testable import LangGraph


// XCTest Documentation
// https://developer.apple.com/documentation/xctest

// Defining Test Cases and Test Methods
// https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
final class LangGraphTests: XCTestCase {
    

    func assertDictionaryOfAnyEqual( _ expected: [String:Any], _ current: [String:Any] ) {
        XCTAssertEqual(current.count, expected.count, "the dictionaries have different size")
        for (key, value) in current {
            
            if let value1 = value as? Int, let value2 = expected[key] as? Int {
                XCTAssertTrue( value1 == value2 )
            }
            if let value1 = value as? String, let value2 = expected[key] as? String {
                XCTAssertTrue( value1 == value2 )
            }
        }

    }
    func testValidation() async throws {
            
        let workflow = GraphState( stateType: BaseAgentState.self )
        
        XCTAssertThrowsError( try workflow.compile() ) {error in 
            print( error )
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
        }
        
        workflow.setEntryPoint("agent_1")

        XCTAssertThrowsError( try workflow.compile() ) {error in
            print( error )
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
        }
        
        try workflow.addNode("agent_1") { state in
            
            print( "agent_1", state )
            return ["prop1": "test"]
        }
        
        XCTAssertNotNil(try workflow.compile())
        
        try workflow.addEdge(sourceId: "agent_1", targetId: END)
        
        XCTAssertNotNil(try workflow.compile())
        
        XCTAssertThrowsError( try workflow.addEdge(sourceId: END, targetId: "agent_1") ) {error in
            print( error )
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
        }
        
        XCTAssertThrowsError(try workflow.addEdge(sourceId: "agent_1", targetId: "agent_2")) { error in
            
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
            if case GraphStateError.duplicateEdgeError(let msg) = error {
                print( "EXCEPTION:", msg )
            }
            else {
                XCTFail( "exception is not expected 'duplicateEdgeError'")
            }
            
        }

        try workflow.addNode("agent_2") { state in
            
            print( "agent_2", state )
            return ["prop2": "test"]
        }
        
        try workflow.addEdge(sourceId: "agent_2", targetId: "agent_3")

        XCTAssertThrowsError( try workflow.compile() ) {error in
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
            if case GraphStateError.missingNodeReferencedByEdge(let msg) = error {
               print( "EXCEPTION:", msg )
            }
            else {
                XCTFail( "exception is not expected 'duplicateEdgeError'")
            }

        }
        
        XCTAssertThrowsError(
            try workflow.addConditionalEdge(sourceId: "agent_1", condition:{ _ in return "agent_3"}, edgeMapping: [:])
        ) { error in
            
            XCTAssertTrue(error is GraphStateError, "\(error) is not a GraphStateError")
            if case GraphStateError.edgeMappingIsEmpty = error {
               print( "EXCEPTION:", error  )
            }
            else {
                XCTFail( "exception is not expected 'duplicateEdgeError'")
            }

        }
        
    }

    func testRunningOneNode() async throws {
            
        let workflow = GraphState( stateType: BaseAgentState.self )
        workflow.setEntryPoint("agent_1")
        try workflow.addNode("agent_1") { state in
            
            print( "agent_1", state )
            return ["prop1": "test"]
        }
        
        try workflow.addEdge(sourceId: "agent_1", targetId: END)
        
        let app = try workflow.compile()
        
        let result = try await app.invoke(inputs: [ "input": "test1"] )
        
        let expected = ["prop1": "test", "input": "test1"]
        assertDictionaryOfAnyEqual( expected, result.data )
        
    }

    struct BinaryOpState : AgentState {
        var data: [String : Any]
        
        init() {
            data = ["add1": 0, "add2": 0 ]
        }
        
        init(_ initState: [String : Any]) {
            data = initState
        }
        var op:String? {
            data["op"] as? String
        }

        var add1:Int? {
            data["add1"] as? Int
        }
        var add2:Int? {
            data["add2"] as? Int
        }
    }

    func testRunningTreeNodes() async throws {
            
        let workflow = GraphState( stateType: BinaryOpState.self )
        
        try workflow.addNode("agent_1") { state in
            
            print( "agent_1", state )
            return ["add1": 37]
        }
        try workflow.addNode("agent_2") { state in
            
            print( "agent_2", state )
            return ["add2": 10]
        }
        try workflow.addNode("sum") { state in
            
            print( "sum", state )
            guard let add1 = state.add1, let add2 = state.add2 else {
                throw GraphRunnerError.executionError("agent state is not valid! expect 'add1', 'add2'")
            }
            
            return ["result": add1 + add2 ]
        }

        try workflow.addEdge(sourceId: "agent_1", targetId: "agent_2")
        try workflow.addEdge(sourceId: "agent_2", targetId: "sum")

        workflow.setEntryPoint("agent_1")
        workflow.setFinishPoint("sum")

        let app = try workflow.compile()
        
        let result = try await app.invoke(inputs: [ : ] )
        
        assertDictionaryOfAnyEqual( ["add1": 37, "add2": 10, "result":  47 ], result.data )

    }

    func testRunningFourNodesWithCondition() async throws {
            
        let workflow = GraphState( stateType: BinaryOpState.self )
        
        try workflow.addNode("agent_1") { state in
            
            print( "agent_1", state )
            return ["add1": 37]
        }
        try workflow.addNode("agent_2") { state in
            
            print( "agent_2", state )
            return ["add2": 10]
        }
        try workflow.addNode("sum") { state in
            
            print( "sum", state )
            guard let add1 = state.add1, let add2 = state.add2 else {
                throw GraphRunnerError.executionError("agent state is not valid! expect 'add1', 'add2'")
            }
            
            return ["result": add1 + add2 ]
        }
        try workflow.addNode("mul") { state in
            
            print( "mul", state )
            guard let add1 = state.add1, let add2 = state.add2 else {
                throw GraphRunnerError.executionError("agent state is not valid! expect 'add1', 'add2'")
            }
            
            return ["result": add1 * add2 ]
        }

        let choiceOp:EdgeCondition<BinaryOpState> = { state in
            
            guard let op = state.op else {
                return "noop"
            }
            
            switch( op ) {
            case "sum":
                return "sum"
            case "mul":
                return "mul"
            default:
                return "noop"
            }
        }
        
        try workflow.addEdge(sourceId: "agent_1", targetId: "agent_2")
        try workflow.addConditionalEdge(sourceId: "agent_2",
                                        condition: choiceOp,
                                        edgeMapping: ["sum":"sum", "mul":"mul", "noop": END] )
        try workflow.addEdge(sourceId: "sum", targetId: END)
        try workflow.addEdge(sourceId: "mul", targetId: END)
        
        workflow.setEntryPoint("agent_1")

        let app = try workflow.compile()
        
        let resultMul = try await app.invoke( inputs: [ "op": "mul" ] )
        
        assertDictionaryOfAnyEqual(["op": "mul", "add1": 37, "add2": 10, "result": 370 ], resultMul.data)
        
        let resultAdd = try await app.invoke( inputs: [ "op": "sum" ] )
        
        assertDictionaryOfAnyEqual(["op": "sum", "add1": 37, "add2": 10, "result": 47 ], resultAdd.data)
    }

    
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

    }
    
    func testParseDiagramDescriptionOutput() async throws {
        
        let output = 
"""
```json
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
    "containers": [
        { "name": "Stream Processor", "children": ["Preprocessing", "LLM Application", "Postprocessing"], "description": "Processes the event stream" }
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
```
"""
        
        let dd = try diagramDescriptionOutputParse( output )
        
        XCTAssertNotNil(dd)
        XCTAssertEqual("process", dd.type, "Type are different!")
        XCTAssertEqual("LLM Application Data Flow", dd.title, "Title are different!")
        
    }
    
}
