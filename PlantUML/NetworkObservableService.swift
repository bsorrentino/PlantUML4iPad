//
//  NetworkMonitor.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 27/11/24.
//

import Network
import SwiftUI

class NetworkObservableService: ObservableObject {
    let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    
    init() {
        monitor.pathUpdateHandler = { path in
            print( "network path update: \(path)")
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}


struct NetworkEnabledModifier: ViewModifier {
    
    @ObservedObject var networkService: NetworkObservableService
    
    func body(content: Content) -> some View {
        content
            .disabled(!networkService.isConnected)
    }
}

struct NetworkEnabledStyleModifier: ViewModifier {
    
    @ObservedObject var networkService: NetworkObservableService
    
    func body(content: Content) -> some View {
        content
            // Change color when disabled
            // .foregroundColor(networkService.isConnected ? .blue : .gray)
            // Reduce opacity when disabled
            .opacity(networkService.isConnected ? 1 : 0.5)
    }
}

//
// MARK: - Metwork extension
//

extension View {
    
    func networkEnabled( _ networkService: NetworkObservableService ) -> some View {
        modifier(NetworkEnabledModifier(networkService: networkService))
    }

    func networkEnabledStyle( _ networkService: NetworkObservableService ) -> some View {
        modifier(NetworkEnabledStyleModifier(networkService: networkService))
    }


}
