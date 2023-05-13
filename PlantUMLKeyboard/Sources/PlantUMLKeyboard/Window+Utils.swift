//
//  Window+Utils.swift
//  
//
//  Created by Bartolomeo Sorrentino on 13/09/22.
//

import UIKit

/*
public func getKeyboardWindow() -> UIWindow? {
//    let _ =  UIApplication.shared.connectedScenes
//                // Keep only active scenes, onscreen and visible to the user
//                //.filter { $0.activationState == .foregroundActive }
//                // Keep only the first `UIWindowScene`
//                //.first(where: { $0 is UIWindowScene })
//                // Get its associated windows
//                .compactMap { $0 as? UIWindowScene }
//                .compactMap { $0.windows }
//                .flatMap { $0 }
//                .last
    return UIApplication.shared.windows.last
}
*/

public func getFirstScene() -> UIWindowScene? {
    

    let scenes = UIApplication.shared.connectedScenes
    guard let windowScene = scenes.first as? UIWindowScene else {
        return nil
    }

    return windowScene

}

public func getWindows() -> [UIWindow]? {
    
    return getFirstScene()?.windows

}

func getRootViewController() -> UIViewController? {
    getWindows()?.first?.rootViewController
}

func getFirstTextFieldResponder() -> UITextField? {
    
    guard let firstWindow = getWindows()?.first, let firstResponder = firstWindow.firstResponder else {
        return nil
    }
    
    return firstResponder as? UITextField
}

