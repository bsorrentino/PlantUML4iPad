//
//  SwiftUIView.swift
//
//
//  Created by Bartolomeo Sorrentino on 28/11/22.
//
// Inspired by [How to detect device rotation](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation)

import SwiftUI
import Combine
import OSLog

struct  InterfaceOrientationHolder {

    var value:UIInterfaceOrientation {
        
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        else  {
            return .unknown
        }

    }
}

private struct InterfaceOrientationKey: EnvironmentKey {
    static let defaultValue = InterfaceOrientationHolder()
}

extension EnvironmentValues {
  var interfaceOrientation: InterfaceOrientationHolder {
    get { self[InterfaceOrientationKey.self] }
      set { os_log( "InterfaceOrientationKey is read only!",  type: .info) }
  }
}

// Our custom view modifier to track rotation and
// call our action
struct DeviceRotationViewModifier: ViewModifier {
    
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
