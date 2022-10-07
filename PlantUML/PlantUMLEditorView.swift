//
//  ContentView.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI
import Combine
import PlantUMLFramework
import PlantUMLKeyboard

// [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
enum Focusable: Hashable {
  case none
  case row(id: String)
}

struct PlantUMLEditorView: View {
    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    
    @EnvironmentObject private var diagram: PlantUMLDiagramObject
    
    @Binding var document: PlantUMLDocument
    
    @FocusState private var focusedItem: Focusable?
    
    @State private var isEditorVisible = true
    @State private var isPreviewVisible = true
    @State private var isScaleToFit = true

    var body: some View {
        GeometryReader { geometry in
            HStack {
                if( isEditorVisible ) {
                    EditorView()
                        .modifier( KeyboardAdaptive() )
                    //  .onReceive( customKeyboard.$itemsToAdd ) { items in
                    //        appendBelow(values: items)
                    //  }
                }
                if isPreviewVisible {
                    if isScaleToFit {
                        PlantUMLDiagramView( url: diagram.buildURL() )
                    }
                    else {
                        PlantUMLScrollableDiagramView( url: diagram.buildURL(), size: geometry.size )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    EditButton()
                    SaveButton()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ScaleToFitButton()
                    HStack( spacing: 0 ) {
                        ToggleEditorButton()
                        TogglePreviewButton()
                    }
                }
                
            }
        }
    }
    
    
    func SaveButton() -> some View {
        
        Button( action: saveToDocument ) {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
                .labelStyle(.titleOnly)
        }
    }

    func ScaleToFitButton() -> some View {
        
        Toggle("fit image", isOn: $isScaleToFit)
    }

    func TogglePreviewButton() -> some View {
        
        Button {
            withAnimation {
                isPreviewVisible.toggle()
                if !isPreviewVisible && !isEditorVisible  {
                    isEditorVisible.toggle()
                }
            }
        }
        label: {
            Label( "Toggle Preview", systemImage: "rectangle.righthalf.inset.filled" )
                .labelStyle(.iconOnly)
                .foregroundColor( isPreviewVisible ? .blue : .gray)
                
        }
    }

    func ToggleEditorButton() -> some View {
        
        Button {
            withAnimation {
                isEditorVisible.toggle()
                if !isEditorVisible && !isPreviewVisible  {
                    isPreviewVisible.toggle()
                }

            }
        }
        label: {
            Label( "Toggle Editor", systemImage: "rectangle.lefthalf.inset.filled" )
                .labelStyle(.iconOnly)
                .foregroundColor( isEditorVisible ? .blue : .gray)

        }
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

    func AddAboveButton( theItem item: SyntaxStructure ) -> some View {
        
        return Button {
            addNewItem( relativeToItem: item, atPosition: .ABOVE )
        } label: {
            Label( "add above",
                   systemImage: "arrow.up")
            .labelStyle(.titleAndIcon)
            
        }
    }

    func AddBelowButton( theItem item: SyntaxStructure ) -> some View {
        
        return Button {
            addNewItem( relativeToItem: item, atPosition: .BELOW )
        } label: {
            Label( "add below",
                   systemImage: "arrow.down")
            .labelStyle(.titleAndIcon)
        }
    }

    // MARK: Editor View
    func EditorView() -> some View {
        
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

                    PlantUMLTextFieldWithCustomKeyboard( item: item,
                                                         onChange: updateItem,
                                                         onAddNew: addNewItem )
                        .focused($focusedItem, equals: .row(id: item.id))
                }

            }
            .onMove(perform: move)
            .onDelete( perform: delete)

        }
        .font(.footnote)
        .listStyle(SidebarListStyle())

    }
    

}

// MARK: ACTIONS
extension PlantUMLEditorView {
    
    internal func saveToDocument() {
        document.text = diagram.description
    }
    
    @available(*, deprecated, message: "no longer valid!")
    internal func indexFromFocusedItem() -> Int? {
        logger.trace( "indexFromFocusedItem" )
        
        var result:Int? = nil
        
        if case .row(let id) = focusedItem {
            
            result = diagram.items.firstIndex { $0.id == id }
            logger.trace( "indexFromFocusedItem: \(result ?? -1 )" )
            
            return result
        }
        
        return result
    }
    
    func updateItem( item: SyntaxStructure, withValue value: String, andAdditionalValues values: [String]? ) {

        guard let offset = diagram.items.firstIndex( where: { $0.id == item.id } )  else {
            logger.debug( "update failed!" )
            return
        }
        
        diagram.items[ offset ].rawValue = value
        
        logger.debug( "update at \(offset): \(value)" )
        
        if let values = values {
            addItemsBelow(theOffset: offset, values: values)
        }
   }

    func addNewItem( relativeToItem item: SyntaxStructure, atPosition pos: AppendActionPosition, value: String? = nil ) {
        let offset = diagram.items.firstIndex { $0.id == item.id }

        guard let offset = offset else { return }
        let newItem = SyntaxStructure( rawValue: value ?? "")

        switch( pos ) {
        case .BELOW:
            diagram.items.insert( newItem, at: offset + 1)
        case .ABOVE:
            diagram.items.insert( newItem, at: offset )
        }
        
        focusedItem = .row( id: newItem.id )
   }

    func addItemsBelow( theOffset offset: Int, values: [String]  ) {
        
        values.map { SyntaxStructure( rawValue: $0) }
            .enumerated()
            .forEach { (index, item ) in
                diagram.items.insert( item, at: offset + index + 1)
            }
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
        PlantUMLEditorView(document: .constant(PlantUMLDocument()))
            .environment(\.editMode, Binding.constant(EditMode.inactive))
            .previewInterfaceOrientation(.landscapeRight)
            .environmentObject( PlantUMLDiagramObject( text:
"""

title test

"""))
    }
}
