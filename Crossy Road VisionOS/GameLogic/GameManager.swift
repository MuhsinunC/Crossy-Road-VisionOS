# Manages game state, score, level generation 

import SwiftUI // For ObservableObject
import RealityKit
import ARKit // For ARAnchor types
import Combine // For cancellables

@MainActor // Ensure methods interacting with RealityKit run on main actor
class GameManager: ObservableObject {

    @Published var currentGameState: GameState = .setup
    @Published var score: Int = 0

    private var rootEntity: Entity? // The main anchor on the table
    private var playerEntity: ModelEntity?

    // Level Generation state
    private var activeLanes: [Entity] = [] // Keep track of current lanes
    private var nextLaneIndex: Int = 0
    private let maxVisibleLanes = 15 // How many lanes to keep loaded

    // Timers or mechanisms for spawning
    private var obstacleSpawnTimer: Timer? // Example timer

    // ARKit state
    private var tableAnchorFound = false
    private var planeAnchorID: UUID?


    // --- Game Lifecycle ---

    func setupGame(rootEntity: Entity) async {
         print("GameManager: Setting up game...")
         self.rootEntity = rootEntity
         self.currentGameState = .setup
         self.score = 0
         self.nextLaneIndex = 0
         self.activeLanes.removeAll()
         self.playerEntity = nil
         self.tableAnchorFound = false // Reset plane finding state
         self.planeAnchorID = nil
         stopObstacleSpawning() // Ensure timer is stopped

         // Pre-load initial assets if desired (can improve initial spawn time)
         // _ = try? await EntityFactory.createPlayerEntity()
         // _ = try? await EntityFactory.createLaneEntity(type: .grass, index: 0)
         // _ = try? await EntityFactory.createObstacleEntity(type: .car, laneIndex: 1)
     }


    func startGame() async {
        guard let rootEntity = self.rootEntity, currentGameState == .ready || currentGameState == .gameOver else {
            print("GameManager: Cannot start game in state \(currentGameState)")
            return
        }
        print("GameManager: Starting game...")

        // Reset score only if starting from game over or ready
        if currentGameState != .playing {
             score = 0
             nextLaneIndex = 0
             activeLanes.forEach { $0.removeFromParent() } // Clear old lanes
             activeLanes.removeAll()
             playerEntity?.removeFromParent() // Remove old player
             playerEntity = nil
        }


        currentGameState = .playing

        // Create and place the player
        do {
            playerEntity = try await EntityFactory.createPlayerEntity()
            rootEntity.addChild(playerEntity!)
            print("GameManager: Player placed.")
        } catch {
            print("GameManager: Failed to create player entity: \(error)")
            currentGameState = .gameOver // Or some error state
            return
        }

        // Generate initial lanes
        for i in 0..<maxVisibleLanes / 2 { // Generate some lanes ahead
            await generateNextLane()
        }

        // Start game loops (like obstacle spawning)
        startObstacleSpawning()
    }

    func resetGame() {
        print("GameManager: Resetting game...")
        stopObstacleSpawning()
        // Remove all dynamic entities
        activeLanes.forEach { $0.removeFromParent() }
        activeLanes.removeAll()
        playerEntity?.removeFromParent() // Remove player
        playerEntity = nil
        rootEntity?.children.removeAll() // Clear children from root, except maybe persistent ones

        // Reset state variables
        score = 0
        nextLaneIndex = 0
        currentGameState = .setup // Go back to setup, waiting for plane
        tableAnchorFound = false
        planeAnchorID = nil
        rootEntity = nil // Clear root reference until ImmersiveView provides it again
    }

    func gameOver() {
        print("GameManager: Game Over!")
        currentGameState = .gameOver
        stopObstacleSpawning()
        // Maybe show a game over message or effect
    }

    // --- ARKit Plane Handling ---
     func handlePlaneAnchorUpdate(_ update: AnchorUpdate<PlaneAnchor>, session: ARKitSession) async {
         // Only anchor to the first good table found
         guard !tableAnchorFound else { return }

         let planeAnchor = update.anchor

         // Check if the plane meets criteria (e.g., table classification, minimum size)
         guard planeAnchor.alignment == .horizontal,
               planeAnchor.classification == .table, // Make sure it's classified as a table
               planeAnchor.geometry.minimumExtent(comparingAxes: .xy) > Constants.minTableSize // Ensure it's big enough
         else {
             // If an anchor was removed that we were tracking, reset
             if update.event == .removed && planeAnchor.id == self.planeAnchorID {
                 print("GameManager: Tracked plane anchor removed.")
                 await handleLostTableAnchor()
             }
             return
         }


         if update.event == .added || update.event == .updated {
             print("GameManager: Suitable table plane found/updated: \(planeAnchor.id)")
             tableAnchorFound = true
             self.planeAnchorID = planeAnchor.id


             // Update the rootEntity's anchor to track this specific plane
             if let root = self.rootEntity as? AnchorEntity {
                 // Create a new anchor tracking the specific plane
                 let newAnchor = AnchorEntity(anchor: planeAnchor)

                 // Copy children from the old temporary anchor (if any) to the new one
                 // Note: This simple copy might not be robust if complex setup happened before anchoring
                 let children = root.children.map { $0 } // Copy the collection
                 children.forEach { $0.move(toParent: newAnchor, preservingWorldTransform: true) }


                 // Replace the old rootEntity reference and update the scene
                 // This needs careful handling with RealityView's content management.
                 // A better approach might be to have a placeholder Entity under the initial world anchor,
                 // and move *that* placeholder to the new plane anchor when found.

                 // Simpler for now: Just signal that we are ready
                 print("GameManager: Anchored to table. Ready to place game.")
                 if currentGameState == .setup { // Only transition if we were waiting
                     self.currentGameState = .ready // Now ready to start via button press
                     // Optionally automatically start: await startGame()
                 }


                 // We found our table, stop processing further updates for *new* tables
                 // (We might still want updates for the *same* table if its geometry changes significantly)
                 // session.stop() // Don't stop the whole session, just ignore new planes logic


             } else {
                 print("GameManager: Root entity is not an AnchorEntity or not found.")
             }
         }
     }


     func handleLostTableAnchor() async {
         print("GameManager: Lost table anchor!")
         // Handle the case where the table is no longer detected
         tableAnchorFound = false
         planeAnchorID = nil
         currentGameState = .setup // Or a specific "paused/relocalizing" state
         stopObstacleSpawning()
         // Potentially hide or remove game elements until a new anchor is found
         rootEntity?.children.removeAll() // Example: Clear the scene
         // Inform the user they need to find a table again
     }

    // --- Input Handling ---

    func handleTap(on entity: Entity) {
        guard currentGameState == .playing, let player = playerEntity else { return }

        print("GameManager: Tap detected on entity: \(entity.name)")

        // Example: Move forward if tapping the player or ground just ahead?
        if entity == player || entity.name.starts(with: "Lane") { // Adjust targeting logic
            movePlayer(direction: .forward)
        }
        // Add logic for tapping left/right zones if you implement those
    }

    // --- Player Movement ---

    func movePlayer(direction: PlayerMovementDirection) {
        guard let player = playerEntity, var playerComp = player.components[PlayerComponent.self] else { return }

        var targetPosition = player.position

        switch direction {
        case .forward:
            targetPosition.z -= Constants.laneWidth // Move one lane forward (assuming Z is depth)
            playerComp.currentLaneIndex += 1
            score = max(score, playerComp.currentLaneIndex) // Update score based on max forward lane
            print("GameManager: Moving player forward to lane \(playerComp.currentLaneIndex)")
            // Trigger generation of new lanes if needed
            Task { await generateAndCleanUpLanes() }
        case .backward:
            targetPosition.z += Constants.laneWidth
            playerComp.currentLaneIndex -= 1
             print("GameManager: Moving player backward to lane \(playerComp.currentLaneIndex)")
        case .left:
            targetPosition.x -= Constants.laneWidth // Assuming X is left/right
             print("GameManager: Moving player left")
        case .right:
            targetPosition.x += Constants.laneWidth
             print("GameManager: Moving player right")

        }

        // Update player component immediately
        player.components.set(playerComp)

        // Animate the movement
        let targetTransform = Transform(scale: player.transform.scale, rotation: player.transform.rotation, translation: targetPosition)
        player.move(to: targetTransform, relativeTo: player.parent, duration: Constants.playerMoveDuration, timingFunction: .easeInOut)

        // TODO: Add collision check *after* movement starts or finishes
        // This might involve a slight delay or checking during the animation.
        // For simplicity, a check could happen immediately based on targetPosition.
        checkCollision(at: targetPosition)
    }

    enum PlayerMovementDirection {
        case forward, backward, left, right
    }


    // --- Level Generation & Cleanup ---

    private func generateAndCleanUpLanes() async {
        guard let player = playerEntity, let playerComp = player.components[PlayerComponent.self] else { return }

        // Generate lanes ahead
        let desiredFurthestLane = playerComp.currentLaneIndex + maxVisibleLanes / 2
        while nextLaneIndex < desiredFurthestLane {
            await generateNextLane()
        }

        // Clean up lanes behind
        let cleanupThreshold = playerComp.currentLaneIndex - maxVisibleLanes / 2
        activeLanes.removeAll { laneEntity in
            guard let laneComp = laneEntity.components[LaneComponent.self] else { return false } // Should have component
            if laneComp.index < cleanupThreshold {
                print("GameManager: Removing lane \(laneComp.index)")
                laneEntity.removeFromParent()
                // Also remove associated obstacles? (Need to track obstacles per lane or query)
                return true // Remove from activeLanes array
            }
            return false
        }
    }


     private func generateNextLane() async {
         guard let root = rootEntity else { return }

         // Determine lane type (add more randomness/patterns later)
         let laneType: LaneComponent.LaneType
         let randomType = Int.random(in: 0..<10)
         if randomType < 4 {
             laneType = .road
         } else if randomType < 7 {
             laneType = .water
         } else {
             laneType = .grass
         }
         // Add train tracks occasionally etc.

         do {
             let laneEntity = try await EntityFactory.createLaneEntity(type: laneType, index: nextLaneIndex)

             // Position the lane
             let zPosition = Constants.playerStartPosition.z - (Float(nextLaneIndex) * Constants.laneWidth)
             laneEntity.position = [0, 0, zPosition] // Centered on X for now
             laneEntity.transform.scale = Constants.laneScale

             root.addChild(laneEntity)
             activeLanes.append(laneEntity)
             print("GameManager: Added \(laneType) lane at index \(nextLaneIndex), positionZ: \(zPosition)")

             nextLaneIndex += 1

         } catch {
             print("GameManager: Failed to create lane \(nextLaneIndex): \(error)")
             // Handle error - maybe stop generation?
         }
     }

    // --- Obstacle Spawning ---

    private func startObstacleSpawning() {
        stopObstacleSpawning() // Ensure no duplicate timers

        obstacleSpawnTimer = Timer.scheduledTimer(withTimeInterval: Constants.obstacleSpawnInterval, repeats: true) { [weak self] _ in
             // Run async task to avoid blocking timer thread
            Task {
                 await self?.spawnObstacleOnRandomLane()
            }
        }
        print("GameManager: Started obstacle spawning.")
    }

    private func stopObstacleSpawning() {
        obstacleSpawnTimer?.invalidate()
        obstacleSpawnTimer = nil
        print("GameManager: Stopped obstacle spawning.")
    }

    private func spawnObstacleOnRandomLane() async {
        guard currentGameState == .playing, let root = rootEntity else { return }

        // Find candidate lanes (e.g., road or water lanes currently visible)
        let candidateLanes = activeLanes.filter { lane in
            guard let comp = lane.components[LaneComponent.self] else { return false }
            return comp.type == .road || comp.type == .water // Only spawn on these types for now
        }

        guard let targetLane = candidateLanes.randomElement(),
              let targetLaneComp = targetLane.components[LaneComponent.self] else {
           // print("GameManager: No suitable lanes for obstacle spawning.")
            return
        }

        let obstacleType: ObstacleComponent.ObstacleType = (targetLaneComp.type == .road) ? .car : .log

        do {
            let obstacleEntity = try await EntityFactory.createObstacleEntity(type: obstacleType, laneIndex: targetLaneComp.index)

            // Determine start position (left or right edge)
            let direction = obstacleEntity.components[ObstacleComponent.self]?.direction ?? Constants.rightDirection
            let startX = (direction == Constants.rightDirection) ? Constants.spawnEdgeDistance : -Constants.spawnEdgeDistance
            let startY = Constants.obstacleYOffset // Adjust vertical position slightly if needed
            let startZ = targetLane.position.z // Align with the lane's depth

            obstacleEntity.position = [startX, startY, startZ]

            // Add to the root (or maybe the lane entity itself if structured differently)
            root.addChild(obstacleEntity)
            // print("GameManager: Spawned \(obstacleType) on lane \(targetLaneComp.index)")

        } catch {
             print("GameManager: Failed to spawn obstacle: \(error)")
        }
    }


    // --- Collision Detection ---

     // Basic placeholder - needs proper implementation using RealityKit physics/collision events
     func checkCollision(at position: SIMD3<Float>) {
         guard let root = rootEntity else { return }
         print("GameManager: Checking collision around position \(position)")

         // This is VERY basic. Proper collision needs CollisionComponent and event subscriptions or queries.
         // Example: Query entities near the player's new position

         let queryBounds = BoundingBox(center: position, extents: [Constants.laneWidth * 0.8, 0.5, Constants.laneWidth * 0.8]) // Small box around target

         let nearbyEntities = root.scene?.performQuery(EntityQuery(bounds: queryBounds)) ?? []

         var onSafeSurface = false
         var hitObstacle = false

         for entity in nearbyEntities {
              if let laneComp = entity.components[LaneComponent.self] {
                  if laneComp.type == .grass || laneComp.type == .trainTrack { // Assuming tracks are safe when no train
                       onSafeSurface = true
                  }
                   // Need to check if on a log if the lane is water
                  else if laneComp.type == .water {
                       // Further check if position overlaps with a log entity on this lane
                      if isPositionOnLog(position: position, waterLaneIndex: laneComp.index) {
                            onSafeSurface = true
                      }
                  } else if laneComp.type == .road {
                      // Road itself isn't safe, need to check for cars
                      onSafeSurface = false // Assume unsafe unless proven otherwise by no car collision
                  }
              } else if let obstacleComp = entity.components[ObstacleComponent.self] {
                   if obstacleComp.type == .car || obstacleComp.type == .train {
                       print("GameManager: Collision with obstacle detected!")
                       hitObstacle = true
                       break // Found a hit, stop checking
                   }
                   // Logs are handled differently (part of safe surface check on water)
              }
         }


         // Determine outcome based on checks
         if hitObstacle {
              gameOver()
         } else if !onSafeSurface {
              // Fell in water or hit by something not explicitly checked? Or just landed on road?
              // If on road, check more accurately for cars. If in water without log -> game over
              // This logic needs refinement based on precise collision results
              print("GameManager: Landed on unsafe surface or water!")
             // Temporarily assume road is safe if no car hit, but water is not
             if !isPositionOnWater(position: position) {
                  // on road, likely safe for now in this basic check
             } else {
                 gameOver() // Fell in water
             }

         } else {
              print("GameManager: Landed safely.")
              // Player is safe on grass, log, or empty track
         }
     }

     // Placeholder helper functions for collision
     private func isPositionOnLog(position: SIMD3<Float>, waterLaneIndex: Int) -> Bool {
         // TODO: Query for log entities specifically on `waterLaneIndex` near `position`
         return false // Placeholder
     }
      private func isPositionOnWater(position: SIMD3<Float>) -> Bool {
          // TODO: Query for water lane entities near `position`
          return false // Placeholder
      }
} 