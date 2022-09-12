import Foundation

class PlantUMLContext {
    private(set) var configuration: Configuration

    var uniqElementNames: [String] = []
    var uniqElementAndTypes: [String: String] = [:]
    // var style: [String: String] = [:]
    private(set) var connections: [String] = []
    private(set) var extnConnections: [String] = []

    private let linkTypeInheritance = "<|--"
    private let linkTypeRealize = "<|.."
    private let linkTypeDependency = "<.."
//    private let linkTypeAssociation = "-->"
//    private let linkTypeAggregation = "--o"
//    private let linkTypeComposition = "--*"
    private let linkTypeGeneric = "--"

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    var index = 0

    func addLinking(item: SyntaxStructure, parent: SyntaxStructure) {
//        let linkTo = parent.name?.removeAngleBracketsWithContent() ?? "___"
//        guard skipLinking(element: parent, basedOn: configuration.relationships.inheritance?.exclude) == false else { return }
//        let namedConnection = (uniqElementAndTypes[linkTo] != nil) ? "\(uniqElementAndTypes[linkTo] ?? "--ERROR--")" : "inherits"
//        var linkTypeKey = item.name! + "LinkType"
//
//        if uniqElementAndTypes[linkTo] == "confirms to" {
//            linkTypeKey = linkTo + "LinkType"
//        }
//
//        var connect = "\(linkTo) \(uniqElementAndTypes[linkTypeKey] ?? "--ERROR--") \(item.name!)"
//        if let relStyle = relationshipStyle(for: namedConnection)?.plantuml {
//            connect += " \(relStyle)"
//        }
//        if let relationshipLabel = self.relationshipLabel(for: namedConnection) {
//            connect += " : \(relationshipLabel)"
//        }
//        connections.append(connect)
    }

    private func skipLinking(element: SyntaxStructure, basedOn excludeElements: [String]?) -> Bool {
//        guard let elementName = element.name else { return false }
//        guard let excludedElements = excludeElements else { return false }
//        return !excludedElements.filter { elementName.isMatching(searchPattern: $0) }.isEmpty
        return false
    }

    func relationshipLabel(for name: String) -> String? {
        if name == "inherits" {
            return configuration.relationships.inheritance?.label
        } else if name == "confirms to" {
            return configuration.relationships.realize?.label
        } else if name == "ext" {
            return configuration.relationships.dependency?.label
        } else {
            return nil
        }
    }

    func relationshipStyle(for name: String) -> RelationshipStyle? {
        if name == "inherits" {
            return configuration.relationships.inheritance?.style
        } else if name == "confirms to" {
            return configuration.relationships.realize?.style
        } else if name == "ext" {
            return configuration.relationships.dependency?.style
        } else {
            return nil
        }
    }

    func uniqName(item: SyntaxStructure, relationship: String) -> String {
        return "\(item.rawValue)-\(relationship)"
    }
}
