import Foundation


/// Swift type representationg an AST element (analogue to SourceKitten's Structure)
public struct SyntaxStructure: Codable, Identifiable, RawRepresentable {
    public private(set) var id: String
    public var rawValue: String
   
    public init( rawValue: String  ) {
        self.id = UUID().uuidString
        self.rawValue = rawValue
    }
}

extension SyntaxStructure : Equatable {
    
}
extension String.StringInterpolation {
    mutating func appendInterpolation(_ item: SyntaxStructure) {
        appendInterpolation(item.rawValue)
    }

//    mutating func appendInterpolation(plantuml item: SyntaxStructure) {
//    }
}
