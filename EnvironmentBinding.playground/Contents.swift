//: A UIKit based Playground for presenting user interface
//
// code from [Get a binding from an environment value in SwiftUI](https://stackoverflow.com/q/69731360/521197)
import SwiftUI
import PlaygroundSupport

private struct IsPresented: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isPresented: Binding<Bool> {
        get {
            let v = self[IsPresented.self]
            print( "isPresented get = \(v.wrappedValue)")
            return v
            
        }
        set {
            print( "isPresented set = \(newValue.wrappedValue)")
            self[IsPresented.self] = newValue
        }
    }
}

//extension View {
//    func isPresented(_ isPresented: Binding<Bool>) -> some View {
//        environment(\.isPresented, isPresented)
//    }
//}

struct ContentView : View {
    @State private var isPresented = false
    
    var body: some View {
        ChildView().environment(\.isPresented, $isPresented)
    }
}

struct ChildView : View {
    @Environment(\.isPresented) var isPresented: Binding<Bool>
    
    var body: some View {
        Button("Test") {
            isPresented.wrappedValue = true
        }
        .fullScreenCover(isPresented: isPresented) {
            Text("Sheet")
        }
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = UIHostingController( rootView: ContentView() )
