import OSLog

typealias PartialAgentState = [String: Any]

typealias NodeAction<Action: AgentState> = ( Action ) async throws -> PartialAgentState
typealias EdgeCondition<Action: AgentState> = ( Action ) async throws -> String

protocol AgentState {
    
    var data: [String: Any] { get }
    
//    subscript(key: String) -> Any? { get }
    
    init()
    init( _ initState: [String: Any] )
    
}

struct BaseAgentState : AgentState {
    
    subscript(key: String) -> Any? {
        data[key]
    }
    
    var data: [String : Any]
    
    init() {
        data = [:]
    }
    
    init(_ initState: [String : Any]) {
        data = initState
    }
    
    
}
enum GraphStateError : Error {
    case duplicateNodeError( String )
    case duplicateEdgeError( String )
    case missingEntryPoint
    case missingNodeReferencedByEdge( String )
    case entryPointNotExist( String )
    case finishPointNotExist( String )
    case missingNodeInEdgeMapping( String )
    case edgeMappingIsEmpty
    case invalidNodeIdentifier( String )
}

enum GraphRunnerError : Error {
    case missingEdge( String )
    case missingNode( String )
    case missingNodeInEdgeMapping( String )
    case executionError( String )
}

let END = "__END__" // id of the edge ending workflow

//enum Either<Left, Right> {
//    case left(Left)
//    case right(Right)
//}


class GraphState<State: AgentState>  {
    enum EdgeValue /* Either */ {
        case id(String)
        case condition( ( EdgeCondition<State>, [String:String] ) )
    }
    
    class Runner {
        
        var stateType: State.Type
        var nodes:Dictionary<String, NodeAction<State>>
        var edges:Dictionary<String, EdgeValue>
        var entryPoint:String
        var finishPoint:String?

        init( owner: GraphState ) {
            
            self.stateType = owner.stateType
            self.nodes = Dictionary()
            self.edges = Dictionary()
            self.entryPoint = owner.entryPoint!
            self.finishPoint = owner.finishPoint
            
            owner.nodes.forEach { [unowned self] node in
                nodes[node.id] = node.action
            }
            
            owner.edges.forEach { [unowned self] edge in
                edges[edge.sourceId] = edge.target
            }
        }
        
        func mergeState( currentState: State, partialState: PartialAgentState ) -> State {
            let newState = currentState.data.merging(partialState, uniquingKeysWith: { (current, _) in
                return current
            })
            return State.init(newState)
        }
        
        
        func nextNodeId( nodeId: String, agentState: State ) async throws -> String {
            
            guard let route = edges[nodeId] else {
                throw GraphRunnerError.missingEdge("edge with node: \(nodeId) not found!")
            }
            
            switch( route ) {
            case .id( let nextNodeId ):
                return nextNodeId
            case .condition( let (condition, mapping)):
                
                let newRoute = try await condition( agentState )
                guard let result = mapping[newRoute] else {
                    throw GraphRunnerError.missingNodeInEdgeMapping("cannot find edge mapping for id: \(newRoute) in conditional edge with sourceId:\(nodeId) ")
                }
                return result
            }
        }
        
        func invoke( inputs: PartialAgentState ) async throws -> State {
            
            var currentState = self.stateType.init( inputs )
            var currentNodeId = entryPoint
            
            repeat {
                
                guard let action = nodes[currentNodeId] else {
                    throw GraphRunnerError.missingNode("node: \(currentNodeId) not found!")
                }

                let partialState = try await action( currentState )
                
                currentState = mergeState( currentState: currentState, partialState: partialState)
                
                if( currentNodeId == finishPoint ) {
                    break
                }

                currentNodeId = try await nextNodeId(nodeId: currentNodeId, agentState: currentState)

            } while( currentNodeId != END )
            
            return currentState
        }

    }

    struct Edge : Hashable, Identifiable{
        var id: String {
            sourceId
        }
        static func == (lhs: GraphState.Edge, rhs: GraphState.Edge) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        
        var sourceId:String
        var target:EdgeValue
        
    }

    private var edges: Set<Edge> = []
    
    struct Node : Hashable, Identifiable {
        static func == (lhs: GraphState.Node, rhs: GraphState.Node) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            id.hash(into: &hasher)
        }
        
        var id: String
        var action: NodeAction<State>
    }
    
    private var nodes: Set<Node> = []

    private var entryPoint: String?
    private var finishPoint: String?

    private var stateType: State.Type
    
    init( stateType: State.Type ) {
        self.stateType = stateType
    }
    
    func addNode( _ id: String, action: @escaping NodeAction<State> ) throws {
        let node = Node(id: id,action: action)
        if nodes.contains(node) {
            throw GraphStateError.duplicateNodeError("node with id:\(id) already exist!")
        }
        nodes.insert( node )
        
    }
    func addEdge( sourceId: String, targetId: String ) throws {
        guard sourceId != END else {
            throw GraphStateError.invalidNodeIdentifier( "END is not a valid edge sourceId!")
        }

        let edge = Edge(sourceId: sourceId, target: .id(targetId) )
        if edges.contains(edge) {
            throw GraphStateError.duplicateEdgeError("edge with id:\(sourceId) already exist!")
        }
        edges.insert( edge )
    }
    
    func addConditionalEdge( sourceId: String, condition: @escaping EdgeCondition<State>, edgeMapping: [String:String] ) throws {
        guard sourceId != END else {
            throw GraphStateError.invalidNodeIdentifier( "END is not a valid edge sourceId!")
        }
        if edgeMapping.isEmpty {
            throw GraphStateError.edgeMappingIsEmpty
        }

        let edge = Edge(sourceId: sourceId, target: .condition(( condition, edgeMapping)) )
        if edges.contains(edge) {
            throw GraphStateError.duplicateEdgeError("edge with id:\(sourceId) already exist!")
        }
        edges.insert( edge)
    }
    func setEntryPoint( _ nodeId: String ) {
        entryPoint = nodeId
    }
    
    func setFinishPoint( _ nodeId: String ) {
        finishPoint = nodeId
    }
    
    private var fakeAction:NodeAction<State> = { _ in  return [:] }

    private func makeFakeNode( _ id: String ) -> Node {
        Node(id: id, action: fakeAction)
    }
    
    func compile() throws -> Runner {
        guard let entryPoint else {
            throw GraphStateError.missingEntryPoint
        }
        
        guard nodes.contains( makeFakeNode( entryPoint ) ) else {
            throw GraphStateError.entryPointNotExist( "entryPoint: \(entryPoint) doesn't exist!")
        }
        
        if let finishPoint {
            guard nodes.contains( makeFakeNode( finishPoint ) ) else {
                throw GraphStateError.finishPointNotExist( "finishPoint: \(finishPoint) doesn't exist!")
            }
        }
        // TODO check edges
        for edge in edges {
            
            guard nodes.contains( makeFakeNode(edge.sourceId) ) else {
                throw GraphStateError.missingNodeReferencedByEdge( "edge sourceId: \(edge.sourceId) reference a not existent node!")
            }

            switch( edge.target ) {
            case .id( let targetId ):
                guard targetId==END || nodes.contains(makeFakeNode(targetId) ) else {
                    throw GraphStateError.missingNodeReferencedByEdge( "edge sourceId: \(edge.sourceId)  reference a not existent targetId: \(targetId) node!")
                }
                break
            case .condition((_, let edgeMappings)):
                for (_,nodeId) in edgeMappings {
                    guard nodeId==END || nodes.contains(makeFakeNode(nodeId) ) else {
                        throw GraphStateError.missingNodeInEdgeMapping( "edge mapping for sourceId: \(edge.sourceId) contains a not existen nodeId \(nodeId)!")
                    }
                }
            }
        }
        
        return Runner( owner: self )
    }
}
