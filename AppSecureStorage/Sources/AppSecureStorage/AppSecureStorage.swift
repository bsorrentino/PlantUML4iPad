//
//  AppSecureStorage.swift
//  AppSecureStorage
//
//  Created by Bartolomeo Sorrentino

import SwiftUI

@propertyWrapper
struct AppSecureStorage: DynamicProperty {
    @State private var value = ""
    private let key: String
    private let accessibility:KeychainItemAccessibility

    var wrappedValue: String? {
        get {
            KeychainWrapper.standard.string(forKey: key, withAccessibility: self.accessibility)
        }

        nonmutating set {
            guard let newValue else {
                KeychainWrapper.standard.removeObject(forKey: key, withAccessibility: self.accessibility)
                return
            }
            KeychainWrapper.standard.set( newValue, forKey: key, withAccessibility: self.accessibility)
        }
    }

    init(_ key: String, accessibility:KeychainItemAccessibility =  .whenUnlocked ) {
        self.key = key
        self.accessibility = accessibility
    }
}
