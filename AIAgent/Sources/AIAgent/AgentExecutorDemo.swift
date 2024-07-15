//
//  AgentExecutorDemo.swift
//
//
//  Created by bsorrentino on 23/03/24.
//

import Foundation
import OSLog
import OpenAI
import LangGraph


struct AgentExecutorDemoState : AgentState {
    
    var data: [String : Any]
    
    init() {
        data = [:]
    }
    
    init(_ initState: [String : Any]) {
        data = initState
    }
    
    var diagramCode:String? {
        data["diagram_code"] as? String
    }
    
}



public func runTranslateDrawingToPlantUMLDemo<T:AgentExecutorDelegate>( openAI: OpenAI,
                                                                        imageValue: DiagramImageValue,
                                                                        delegate:T ) async throws -> String? {
    let workflow = StateGraph { AgentExecutorState() }
    
    try workflow.addNode("agent_describer", action: { state in
        await delegate.progress("starting analyze\ndiagram 👀")
        
        try await Task.sleep( nanoseconds: 5_000_000_000 )
        
        await delegate.progress( "diagram processed ✅")
        
        return [ : ]
        
    })
    
    try workflow.addNode("agent_generic_plantuml", action: { state in
        await delegate.progress("translating diagram to\nGeneric Diagram")
        
        try await Task.sleep( nanoseconds: 5_000_000_000 )
        
        let content =
     """
     actor "User Initiating The Diagram Translation Process" as userInitiatingTheDiagramTranslationProcess<<User initiating the diagram translation process>>
     rectangle "Provide Diagram Image" as provideDiagramImage<<Process of providing a diagram image>>
     rectangle "Process Image" as processImage<<Process of processing the provided image>>
     rectangle "Description" as description<<Block describing the image>>
     rectangle "Check Type" as checkType<<Decision block to determine the type of diagram>>
     rectangle "Sequence" as sequence<<Indicates a sequence diagram type>>
     rectangle "Generic" as generic<<Indicates a generic diagram type>>
     rectangle "Translate To Sequence" as translateToSequence<<Action to translate to a sequence diagram>>
     rectangle "Translate To Generic" as translateToGeneric<<Action to translate to a generic diagram>>
     legend
     - 1. The USER initiates the process.
     - 2. The USER provides the diagram image.
     - 3. The PROVIDED DIAGRAM IMAGE is processed.
     - 4. The process results in a DESCRIPTION of the image.
     - 5. The DESCRIPTION leads to a CHECK TYPE decision.
     - 6. Based on the decision, if the diagram is a sequence type, it proceeds to TRANSLATE TO SEQUENCE.
     - 7. If the diagram is a generic type, it proceeds to TRANSLATE TO GENERIC.
     end legend
     userInitiatingTheDiagramTranslationProcess --> provideDiagramImage : User provides a diagram image
     provideDiagramImage --> processImage : Provided image is processed
     processImage --> description : Processed image is described
     description --> checkType : Description leads to checking the type
     checkType --> sequence : Decision made for sequence type
     checkType --> generic : Decision made for generic type
     sequence --> translateToSequence : Sequence type is translated
     generic --> translateToGeneric : Generic type is translated
     
     """
        return [ "diagram_code": content ]
        
    })
    
    try workflow.addEdge(sourceId: "agent_generic_plantuml", targetId: END)
    
    try workflow.addEdge( sourceId: "agent_describer",
                          targetId: "agent_generic_plantuml" )
    
    try workflow.setEntryPoint( "agent_describer")
    
    let app = try workflow.compile()
    
    let inputs:[String : Any] = [:]
    
    let response = try await app.invoke( inputs: inputs)
    
    return response.diagramCode
}


let usecase_description = """
```json
{
 "type": "usecase",
 "title": "TEST Diagram",
 "participants": [
     { "name": "Person", "shape": "actor", "description": "External user or system" },
     { "name": "A", "shape": "ellipse", "description": "Use case A" },
     { "name": "B", "shape": "ellipse", "description": "Use case B" },
     { "name": "C", "shape": "ellipse", "description": "Use case C" },
     { "name": "D", "shape": "ellipse", "description": "Use case D" }
 ],
 "relations": [
     { "source": "Person", "target": "A", "description": "interacts with" },
     { "source": "Person", "target": "B", "description": "interacts with" },
     { "source": "Person", "target": "C", "description": "interacts with" },
     { "source": "Person", "target": "D", "description": "interacts with" }
 ],
 "containers": [
     { "name": "TEST", "children": ["A", "B", "C", "D"], "description": "Container for use cases" }
 ],
 "description": [
     "1. The 'Person' actor interacts with Use Case 'A' within the 'TEST' container.",
     "2. The 'Person' actor interacts with Use Case 'B' within the 'TEST' container.",
     "3. The 'Person' actor interacts with Use Case 'C' within the 'TEST' container.",
     "4. The 'Person' actor interacts with Use Case 'D' within the 'TEST' container."
 ]
}
```
"""


public func runTranslateDrawingToPlantUMLUseCaseDemo<T:AgentExecutorDelegate>( openAI: OpenAI,
                                                                        imageValue: DiagramImageValue,
                                                                        delegate:T ) async throws -> String? {
    let workflow = StateGraph { AgentExecutorState() }
    
    try workflow.addNode("agent_describer", action: { state in
        await delegate.progress("starting analyze\ndiagram 👀")
        
        try await Task.sleep( nanoseconds: 5_000_000_000 )
        
        await delegate.progress( "diagram processed ✅")
        
        let diagram = try diagramDescriptionOutputParse( usecase_description )
        
        await delegate.progress( "diagram type\n '\(diagram.type)'")
        
        return [ "diagram": diagram ]
        
    })
    
    try workflow.addNode("agent_usecase_plantuml", action: { state in
        try await translateDiagramDescriptionToPlantUML( state: state, openAI:openAI, delegate:delegate )
    })
    
    try workflow.addEdge( sourceId: "agent_describer",
                          targetId: "agent_usecase_plantuml" )
    
    try workflow.addEdge(sourceId: "agent_usecase_plantuml", targetId: END)

    try workflow.setEntryPoint( "agent_describer")
    
    let app = try workflow.compile()
    
    let inputs:[String : Any] = [:]
    
    let response = try await app.invoke( inputs: inputs)
    
    return response.diagramCode
}

