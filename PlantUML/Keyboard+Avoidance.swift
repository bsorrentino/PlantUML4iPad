//
//  SwiftUIView.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 21/09/22.
//
import Combine
import SwiftUI

class KeyboardAvoidance : ObservableObject {
    
    var keyboardRect: AnyPublisher<CGRect, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map {
                guard let rect = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return CGRect.zero
                }
                return rect
                
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGRect.zero }
            
        // 3.
        return Publishers.MergeMany(willShow, willHide).eraseToAnyPublisher()
                
    }
}

struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    @ObservedObject var keyboardAvoidance = KeyboardAvoidance()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .ignoresSafeArea(.keyboard)
            .onReceive(keyboardAvoidance.keyboardRect) { self.keyboardHeight = $0.height }
    }
}
