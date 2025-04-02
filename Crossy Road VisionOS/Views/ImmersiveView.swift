// The main RealityView for the game 

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit // Import ARKit for session and plane detection
// import Combine // No longer needed here

struct ImmersiveView: View {
    @ObservedObject var gameManager: GameManager
    // Remove state flags - no longer needed for update logic
    // @State private var gameWorldEntity = Entity() 
    // @State private var initialAnchorTransformSet = false

    // Remove table anchor target definition
    // private let tableAnchorTarget = AnchorEntity(...)

    var body: some View {
        RealityView { content in
            print("RealityView make running...")
            
            // --- Create Game World Anchor & Entity ---
            // Create a world-anchored entity at a fixed position
            // (e.g., 1m in front, 0.5m down from world origin)
            let worldAnchorPosition: SIMD3<Float> = [0, -0.5, -1.0] // Define position separately
            let worldAnchor = AnchorEntity(world: worldAnchorPosition) // Use explicit initializer
            content.add(worldAnchor)
            
            // Create the game world entity that holds all game elements
            let gameWorldEntity = Entity()
            worldAnchor.addChild(gameWorldEntity) // Add game world as child of the anchor
            
            // Apply a small Y offset to the game world itself if needed (relative to anchor)
            gameWorldEntity.position.y = Constants.gameTableYOffset 
            // --- Game world is now anchored relative to world origin ---

            // --- Apply Initial Head Orientation --- 
            // Use a temporary head anchor to get orientation relative to the world anchor
            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)
            if let headParent = headAnchor.parent { // headParent is the RealityView content root
                 // Convert head pose into the world anchor's coordinate space
                let headTransformInWorldAnchorSpace = worldAnchor.convert(transform: headAnchor.transform, from: headParent)
                // Get forward direction from the head pose relative to the world anchor
                let cameraForward = headTransformInWorldAnchorSpace.matrix.columns.2 
                let forwardOnPlane = normalize(SIMD3<Float>(cameraForward.x, 0, cameraForward.z)) // Project onto anchor's horizontal plane
                let targetRotation = simd_quatf(from: SIMD3<Float>(0, 0, -1), to: forwardOnPlane)
                // Apply orientation rotation TO THE GAME WORLD ENTITY (child of anchor)
                gameWorldEntity.orientation = targetRotation 
                print("ImmersiveView make: Applied initial head orientation to game world.")
            } else {
                print("ImmersiveView make: Warning - Could not get head parent for orientation.")
            }
            content.remove(headAnchor) // Remove temporary anchor
            // ------------------------------------

            // Register systems
            MovementSystem.registerSystem()

            // Setup game manager with the game world entity
            gameManager.setupGame(rootEntity: gameWorldEntity)
            
        } // REMOVE update closure entirely
        
        // --- Input Handling ---
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
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