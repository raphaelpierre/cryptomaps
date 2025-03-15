//
//  cryptomapsApp.swift
//  cryptomaps
//
//  Created by Raphael PIERRE on 15.03.2025.
//

import SwiftUI

@main
struct cryptomapsApp: App {
    @StateObject private var cryptoViewModel = CryptoViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cryptoViewModel)
        }
    }
}
