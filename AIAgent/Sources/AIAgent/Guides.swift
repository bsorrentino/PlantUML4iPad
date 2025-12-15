//
//  Diagram.swift
//  AIAgent
//
//  Created by bsorrentino on 13/12/25.
//

import AnyLanguageModel

enum DiagramGuide {
    //@Generable( description: "relationship between two participants" )
    struct Relation : Codable {
        
        //@Guide(description: "source participant name")
        var source: String
        //@Guide(description: "target participant name")
        var target: String
        //@Guide(description: "relation description")
        var description: String
    }
    
    //@Generable( description: "participant of the diagram" )
    struct Participant : Codable {
        
        //@Guide(description: "participant name")
        var name: String
        //@Guide(description: "participant shape. The acceptable shapes are which ones compliant with plantuml syntax")
        var shape: String
        //@Guide(description: "participant description")
        var description: String
        
    }
    
    
    //@Generable( description: "group containing other participants" )
    struct Group : Codable {
        
        //@Guide(description: "group name")
        var name: String
        //@Guide(description: "list of contained participants")
        var children: [String]
        //@Guide(description: "participant description")
        var description: String
    }
    
    //@Generable(description: "diagram description")
    struct Description : Codable {
        //@Guide(description: "diagram type")
        var type: String
        //@Guide(description: "diagram title")
        var title: String
        var participants: [Participant]
        var relations: [Relation]
        var groups: [Group]
        //@Guide(description: "Step by step description of the diagram with clear indication of participants and actions between them.")
        var description: [String]
        //@Guide(description: "In the case it's not possible transate diagram, report problem here")
        var error: String?

        /*
        enum CodingKeys: String, CodingKey {
            case type,title, participants, relations, containers, description
            
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
    
            type = try container.decode(String.self, forKey: .type)
            title = try container.decode(String.self, forKey: .title)
            description = try container.decode([String].self, forKey: .description)
            participants = try container.decode([Participant].self, forKey: .participants)
            relations = try container.decodeIfPresent([Relation].self, forKey: .relations) ?? []
            containers = try container.decodeIfPresent([Container].self, forKey: .containers) ?? []
        }
        */
        
    }
    
    //@Generable(description: "diagram typology")
    enum Typology : Codable {
        case Sequence
        case Generic
    }
}


@Generable( description: "PlantUML result")
struct PlantUMLResult {
    
    @Guide( description: "PlantUML diagram script in the format of PlantUML language")
    var script: String
}
