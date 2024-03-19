//
//  ActivityView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 21/01/24.
//

import SwiftUI

extension Notification.Name {
    static let activityCancelled = Notification.Name("activityCancelled")
}

struct ActivityView<Content>: View where Content: View {
    @Environment( \.colorScheme) var colorScheme
    
    var isShowing: Bool
    var label: String = "Loading ..."
    var content: () -> Content
    
    private var borderColor: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    private var textColor: Color {
        colorScheme == .light ? Color.white : Color.black
    }
    private var rectangleBackgroundColor: Color {
        colorScheme == .light ? Color.black.opacity(0.75) : Color.white
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                self.content()
                    .disabled(self.isShowing)
                    .blur(radius: self.isShowing ? 3 : 0)
                
                if isShowing {
                    
                    let h = geometry.size.height * 0.25
                    rectangleBackgroundColor
                        .border(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay {
                            VStack {
                                Spacer()
                                ProgressView {
                                    VStack{
                                        Text(label)
                                            .font(.title)
                                            .foregroundColor(textColor)
                                    }
                                }
                                .controlSize(.large)
                                .tint(textColor)
                                
                                Spacer()
                                
                                Button( action: {
                                    NotificationCenter.default.post(name: .activityCancelled, object: nil)
                                }) {
                                    Text("Cancel")
                                        .font(.title)
                                        .tint(.red)
                                }
                                .padding()
                                
                            }
                            .frame( height: h)
                            //                            .border(Color.red)
                        }
                        .frame( width: geometry.size.width * 0.4,
                                height: h )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.opacity(self.isShowing ? 1 : 0)
                }
            }
        }
    }
}

fileprivate struct onCancelModifier: ViewModifier {
    var onCancel: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .activityCancelled) ) { _ in onCancel() }
    }
}


extension ActivityView {
    
    func onCancel( _ cancel: @escaping  () -> Void) -> some View {
        self.modifier( onCancelModifier(onCancel: cancel))
    }
    
}


#Preview {
    
    struct MyPreview : View {
        @Environment( \.colorScheme) var colorScheme
        
        private var foreColor: Color {
            colorScheme == .light ? Color.white : Color.black
        }
        var body: some View {
            ActivityView(isShowing: true, label: "Loading process\nand other" ) {
                
                Rectangle()
                    .foregroundColor(foreColor)
                    
            }
            .onCancel {
                print( "on cancel")
            }        }
        
    }

    return MyPreview()
    
    
}
