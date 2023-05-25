//
//  AppSecureStorage.swift
//  AppSecureStorage
//
//  Created by Bartolomeo Sorrentino

import SwiftUI

@propertyWrapper
public struct AppSecureStorage: DynamicProperty {
//    @State private var value:String?
    private let key: String
    private let accessibility:KeychainItemAccessibility

    public var wrappedValue: String? {
        get {
            KeychainWrapper.standard.string(forKey: key, withAccessibility: self.accessibility)
        }

        nonmutating set {
            if let newValue, !newValue.isEmpty  {
                KeychainWrapper.standard.set( newValue, forKey: key, withAccessibility: self.accessibility)
            }
            else {
                KeychainWrapper.standard.removeObject(forKey: key, withAccessibility: self.accessibility)
            }
//            value = newValue
        }
    }
        
      /// Binding compliant
//    public var projectedValue: Binding<String> {
//        Binding(
//            get: { wrappedValue ?? "" },
//            set: { wrappedValue = $0 }
//        )
//    }
    public init(_ key: String, accessibility:KeychainItemAccessibility =  .whenUnlocked ) {
        self.key = key
        self.accessibility = accessibility
    }
}
