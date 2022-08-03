//
//  ContentView.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI

// [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
enum Focusable: Hashable {
  case none
  case row(id: String)
}

struct PlantUMLTextField: View  {
    @State var value: String
    
    var onChange: ( String ) -> Void
    
    var body: some View {
        TextField( "", text: $value )
            .textInputAutocapitalization(.never)
            .font(Font.system(size: 15).monospaced())
            .submitLabel(.done)
            .onChange(of: value
                      , perform: onChange )

    }
    
}
struct PalntUMLEditorView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var diagram: PlantUMLDiagramObject
    
    @Binding var document: PlantUMLDocument
    
    @FocusState var focusedItem: Focusable?

    func SaveButton() -> some View {
        
        Button( action: saveToDocument ) {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
            // .labelStyle(.titleOnly)
        }
    }

    func PreviewButton() -> some View {
        
        Link(destination: diagram.buildURL(), label: {
            Text("Preview")
                .foregroundColor(.orange)
        })
    }
    
    func AddAboveButton() -> some View {
        
        Button( action: addAbove ) {
            Label( "add above",
                   systemImage: "plus.rectangle")
            .labelStyle(.titleAndIcon)
        }
    }

    func AddBelowButton() -> some View {
        Button( action: addBelow ) {
            Label( "add below",
                   systemImage: "plus.rectangle")
            .labelStyle(.titleAndIcon)
        }
    }

    // MARK: Editor View
    func EditorView() -> some View {
        List() {
            ForEach( diagram.items ) { item in
                
                PlantUMLTextField( value: item.rawValue, onChange: updateItem )
                    .focused($focusedItem, equals: .row(id: item.id))
                    .onSubmit(of: .text) {
                        openURL( diagram.buildURL() )
                    }


            }
            .onMove(perform: move)
            .onDelete( perform: delete)

        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                AddAboveButton()
                AddBelowButton()
            }
         }
        .listStyle(SidebarListStyle())

    }
    
    var body: some View {
        EditorView()
        .toolbar {
            ToolbarItemGroup {
                PreviewButton()
                SaveButton()
            }
        }
        
    }

    internal func saveToDocument() {
        document.text = diagram.description
    }
    
    internal func indexFromFocusedItem() -> Int? {
        if case .row(let id) = focusedItem {
            
            return diagram.items.firstIndex { $0.id == id }
        }
        return nil
    }
    
   func updateItem( newValue value: String ) {
        guard let offset = indexFromFocusedItem() else {
            return
        }
        diagram.items[ offset ].rawValue = value
   }
    
   func addBelow() {
        
        guard let offset = indexFromFocusedItem() else {
            return
        }
        
        let newItem = SyntaxStructure( rawValue: "")
        
        diagram.items.insert( newItem, at: offset + 1)
        focusedItem = .row( id: newItem.id )
    }

    func addAbove() {
        guard let offset = indexFromFocusedItem() else {
            return
        }
        
        let newItem = SyntaxStructure( rawValue: "")
        
        diagram.items.insert( newItem, at: offset )
        focusedItem = .row( id: newItem.id )
    }

    func delete(at offsets: IndexSet) {
        diagram.items.remove(atOffsets: offsets)
        focusedItem = nil
    }
    
    func move(from source: IndexSet, to destination: Int) {
        diagram.items.move(fromOffsets: source, toOffset: destination)
        focusedItem = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PalntUMLEditorView(document: .constant(PlantUMLDocument()))
            .environment(\.editMode, Binding.constant(EditMode.active))
            .previewInterfaceOrientation(.landscapeRight)
    }
}
