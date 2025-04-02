// The main RealityView for the game 

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit // Import ARKit for session and plane detection

struct ImmersiveView: View {
    @ObservedObject var gameManager: GameManager // Use the shared game manager

    // ARKit Session and Data Providers
    @State private var session = ARKitSession()
    @State private var planeData = PlaneDetectionProvider(alignments: [.horizontal]) // Detect horizontal planes

    // Root entity anchored to the real world
    @State private var tableAnchor: AnchorEntity?

    var body: some View {
        RealityView { content in
            // Initial Scene Setup (runs once)
            print("RealityView make running...")

            // Create a root anchor entity for the table (will be updated)
            let rootEntity = AnchorEntity(.world(transform: .identity)) // Temporary world anchor
            content.add(rootEntity)

            // Create the game manager entity (or use the class directly)
            // If using ECS systems, register them here:
            // MovementSystem.registerSystem()

            // Initial game setup call (can be async)
            Task {
                await setupGameScene(content: content, rootEntity: rootEntity)
                await gameManager.setupGame(rootEntity: rootEntity) // Pass root to manager
                await runARSession() // Start looking for planes AFTER initial setup
            }

        } update: { content in
            // Update Scene (runs periodically if needed, often logic is in Components/Systems)
            print("RealityView update running...")
            // You might update SwiftUI overlays here based on gameManager state
        }
        .task {
            // Task runs when the view appears
            // Handled in make's Task now to ensure scene is ready
        }
        .task(priority: .low) {
           // Monitor plane detection updates
            for await update in planeData.anchorUpdates {
                 await gameManager.handlePlaneAnchorUpdate(update, session: session)
            }
        }
        .onDisappear {
            // Stop AR session when view disappears
            session.stop()
            gameManager.resetGame() // Clean up game state
            print("AR Session Stopped.")
        }
        // --- Input Handling ---
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
            // Handle tap events on entities
            gameManager.handleTap(on: value.entity)
        })
    }

    // Function to set up the AR Session
    private func runARSession() async {
        print("Attempting to run AR Session...")
        do {
            // Request authorization (important!)
             let authStatus = await session.requestAuthorization(for: [.worldSensing])
             guard authStatus[.worldSensing] == .authorized else {
                 print("ARKit World Sensing authorization denied.")
                 // Handle lack of authorization
                 return
             }
            // Run the session with plane detection
            try await session.run([planeData])
            print("AR Session running with plane detection.")
        } catch {
            print("Failed to run AR session: \(error)")
        }
    }

    // Function for initial scene elements (like loading static assets)
    private func setupGameScene(content: RealityViewContent, rootEntity: Entity) async {
        // Example: Load a simple non-moving element if needed
        // let basePlatform = try? await ModelEntity(named: "platform.usdz")
        // rootEntity.addChild(basePlatform)
        print("Initial game scene setup complete.")
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}