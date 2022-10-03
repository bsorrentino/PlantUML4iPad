import SwiftUI
import UIKit

struct PlantUMLKeyboardView: View {
    
    var onHide:() -> Void
    var onPressSymbol: (Symbol) -> Void
    
    var body : some View{
        
        ZStack(alignment: .topLeading) {
            
            TabView {
                ContentView( .common )
                    .tabItem {
                        Label( PlantUMLSymbolGroup.common.rawValue, systemImage: "list.dash")
                            .labelStyle(.titleOnly)
                    }
                ContentView( .sequence )
                    .tabItem {
                        Label( PlantUMLSymbolGroup.sequence.rawValue, systemImage: "square.and.pencil")
                            .labelStyle(.titleOnly)
                    }
            }
            .frame(maxWidth: .infinity )
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
            
            Button(action: onHide) {
                Image(systemName: "xmark").foregroundColor(.black)
            }
            .padding()
                
        }
    }
    
    func ContentView( _ group: PlantUMLSymbolGroup ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack(spacing: 15){
                
                ForEach( Array(group.symbols.enumerated()), id: \.offset) { rowIndex, i in
                    
                    HStack(spacing: 10) {
                        
                        ForEach( Array(i.enumerated()), id: \.offset ) { cellIndex, symbol in
                            
                            Button {
                                
                                onPressSymbol(symbol)
                                
                            } label: {
                                
                                ButtonLabel( for: group, row: rowIndex, cell: cellIndex, symbol: symbol )
                                
                            }
                            .buttonStyle( KeyButtonStyle() )
                        }
                    }
                }
            }
            .padding(.top)
        
        }
    }
}

fileprivate struct KeyButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .border( .black, width: 1)
            .background( .white )
    }
}


extension PlantUMLKeyboardView {
    
    func ButtonLabel( for group: PlantUMLSymbolGroup, row: Int, cell: Int, symbol: Symbol ) -> some View  {
        
        Group {
            if group.images.isEmpty || group.images[row].isEmpty || group.images[row].isEmpty || group.images[row][cell]==nil
            {
                Text(symbol.description)
                    .font(.system(size: 16).bold())

            }
            else {
                let img = group.images[row][cell]
                Image( uiImage: img! )
                    .resizable()
                    .frame(width: 40, height: 20)
            }
        }
    }
}

struct PlantUMLKeyboardView_Previews: PreviewProvider {
        
    static var previews: some View {
        PlantUMLKeyboardView( onHide: { }, onPressSymbol: { _ in } )
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
