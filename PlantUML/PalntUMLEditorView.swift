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
    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var diagram: PlantUMLDiagramObject
    
    @Binding var document: PlantUMLDocument
    
    @FocusState private var focusedItem: Focusable?
    
    @State private var isPreviewVisible = false
    
    func SaveButton() -> some View {
        
        Button( action: saveToDocument ) {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
                .labelStyle(.titleOnly)
        }
    }

    func PreviewButton() -> some View {
        
        Button {
            withAnimation {
                isPreviewVisible.toggle()
            }
        }
        label: {
            Label( "Preview", systemImage: "" )
                .labelStyle(.titleOnly)
        }
//        Link(destination: diagram.buildURL(), label: {
//            Text("Preview")
//                .foregroundColor(.orange)
//        })
    }
    func AddCloneButton( theItem item: SyntaxStructure ) -> some View {
        
        return Button {
            clone( theItem: item )
        } label: {
            Label( "clone",
                   systemImage: "arrow.down.doc")
            .labelStyle(.titleAndIcon)
        }
    }

    
    func AddAboveButton( theItem item: SyntaxStructure? = nil ) -> some View {
        
        return Button {
            addAbove( theItem: item )
        } label: {
            Label( "add above",
                   systemImage: "arrow.up")
            .labelStyle(.titleAndIcon)
        }
    }

    func AddBelowButton( theItem item: SyntaxStructure? = nil ) -> some View {
        
        return Button {
            addBelow( theItem: item )
        } label: {
            Label( "add below",
                   systemImage: "arrow.down")
            .labelStyle(.titleAndIcon)
        }
    }

    // MARK: Editor View
    func PlantUMLEditorView() -> some View {
        List() {
            ForEach( diagram.items ) { item in
                
                HStack {
                    if editMode?.wrappedValue != .active {
                        Image(systemName: "plus")
                            .contextMenu {
                                AddBelowButton( theItem: item )
                                AddAboveButton( theItem: item )
                                AddCloneButton( theItem: item )
                            }
                    }
                    PlantUMLTextField( value: item.rawValue, onChange: updateItem )
                        .focused($focusedItem, equals: .row(id: item.id))
                        .onSubmit(of: .text) {
                            // openURL( diagram.buildURL() )
                        }
                }


            }
            .onMove(perform: move)
            .onDelete( perform: delete)

        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                AddBelowButton()
                AddAboveButton()
            }
         }
        .listStyle(SidebarListStyle())

    }
    
    var body: some View {
        HStack {
            PlantUMLEditorView()
            if !isPreviewVisible {
                PlantUMLDiagramView( url: diagram.buildURL() )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                PreviewButton()
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                EditButton()
                SaveButton()
            }
        }
        
    }

}

// MARK: ACTIONS
extension PalntUMLEditorView {
    
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
    
    func addBelow( theItem item: SyntaxStructure? ) {
        let offset = (item != nil) ?
            diagram.items.firstIndex { $0.id == item!.id } :
            indexFromFocusedItem()

        guard let offset = offset else { return }
        let newItem = SyntaxStructure( rawValue: "")
        
        diagram.items.insert( newItem, at: offset + 1)
        focusedItem = .row( id: newItem.id )
    }

    func addAbove( theItem item: SyntaxStructure? ) {
        let offset = (item != nil) ?
            diagram.items.firstIndex { $0.id == item!.id } :
            indexFromFocusedItem()

        guard let offset = offset else { return }

        let newItem = SyntaxStructure( rawValue: "")
        
        diagram.items.insert( newItem, at: offset )
        focusedItem = .row( id: newItem.id )
    }

    func clone( theItem item: SyntaxStructure ) {
        guard let offset = diagram.items.firstIndex( where: { $0.id == item.id } ) else {
            return
        }
        
        let newItem = SyntaxStructure( rawValue: item.rawValue)
        
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
