import Foundation


/// Swift type representationg an AST element (analogue to SourceKitten's Structure)
struct SyntaxStructure: Codable, Identifiable {
    var id: String = UUID().uuidString
    var rawValue: String
    
}


extension String.StringInterpolation {
    mutating func appendInterpolation(_ item: SyntaxStructure) {
        appendInterpolation(item.rawValue)
    }

//    mutating func appendInterpolation(plantuml item: SyntaxStructure) {
//    }
}
