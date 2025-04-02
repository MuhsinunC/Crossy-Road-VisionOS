// The main RealityView for the game 

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit // Import ARKit for session and plane detection

struct ImmersiveView: View {
    @ObservedObject var gameManager: GameManager // Use the shared game manager

    // Remove ARKit Session and Data Providers
    // @State private var session = ARKitSession()
    // @State private var planeData = PlaneDetectionProvider(alignments: [.horizontal]) // Detect horizontal planes

    // Root entity is now the table anchor directly managed by RealityView
    // @State private var tableAnchor: AnchorEntity?

    var body: some View {
        RealityView { content in
            // Initial Scene Setup (runs once)
            print("RealityView make running...")

            // Create an anchor that automatically finds a horizontal table plane
            let tableAnchor = AnchorEntity(
                .plane(.horizontal, classification: .table, minimumBounds: [Constants.minTableSize, Constants.minTableSize])
            )
            content.add(tableAnchor)

            // Register systems if needed (do this once)
            MovementSystem.registerSystem()

            // Setup game manager with the anchor RealityKit will manage
            // No need for async setup related to plane finding here
            gameManager.setupGame(rootEntity: tableAnchor)
            // Consider triggering startGame from ContentView or based on gameManager state change
            // For simplicity now, let's assume setup implies ready for button press
            gameManager.currentGameState = .ready // Update state after setup

            // Remove the Task that manually ran setup/ARSession
            // Task { ... }

        } update: { content in
            // Update Scene (runs periodically if needed, often logic is in Components/Systems)
            print("RealityView update running...")
            // You might update SwiftUI overlays here based on gameManager state
        }
        .onDisappear {
            // Stop AR session is no longer needed here
            // session.stop()
            gameManager.resetGame() // Clean up game state
            print("ImmersiveView disappeared. Game reset.")
        }
        // --- Input Handling ---
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            // Handle tap events on entities
            gameManager.handleTap(on: value.entity)
        })
    }

    // Remove the manual AR Session functions
    // private func runARSession() async { ... }
    // private func setupGameScene(rootEntity: Entity) async { ... } // Simple setup done in make

}

#Preview(immersionStyle: .mixed) {
    // Create a GameManager instance specifically for the preview
    ImmersiveView(gameManager: GameManager())
}