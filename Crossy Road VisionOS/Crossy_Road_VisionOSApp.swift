//
//  Crossy_Road_VisionOSApp.swift
//  Crossy Road VisionOS
//
//  Created by Muhsinun on 4/1/25.
//

import SwiftUI

@main
struct Crossy_Road_VisionOSApp: App {
    // StateObject to manage game state across the app if needed outside the immersive view
    @State private var gameManager = GameManager()

    var body: some Scene {
        // Main window for initial UI like a start button
        WindowGroup {
            ContentView(gameManager: gameManager)
        }
        .windowStyle(.plain) // Use a standard window

        // Define the immersive space where the game will run
        ImmersiveSpace(id: "ImmersiveGameSpace") {
            ImmersiveView(gameManager: gameManager)
        }
        // Optional: Define default immersion style if needed
        // .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
