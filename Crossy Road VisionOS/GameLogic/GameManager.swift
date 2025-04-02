// Manages game state, score, level generation 

import SwiftUI // For ObservableObject
import RealityKit
import ARKit // For ARAnchor types
import Combine // For cancellables

// Enum for different game states (MOVED TO TOP)
enum GameState {
    case menu
    case playing
    case gameOver
}

@MainActor // Ensure methods interacting with RealityKit run on main actor
class GameManager: ObservableObject {

    @Published var gameState: GameState = GameState.menu
    @Published var score: Int = 0
    @Published var isImmersiveSpaceOpen: Bool = false // Track if the immersive space is open

    // Game world and entities
    private var gameWorldEntity = Entity()
    private var playerEntity: ModelEntity?
    private var activeLanes: [Int: Entity] = [:]
    private var activeObstacles: Set<Entity> = Set()
    private var laneIndexCounter = 0
    private var cancellables = Set<AnyCancellable>()

    // New properties for ARKit integration
    private var worldTrackingProvider: WorldTrackingProvider? = nil
    private var sceneRootEntity: Entity? = nil
    private var isSetupComplete: Bool = false
    private var dynamicWorldAnchor: AnchorEntity? = nil // To hold the dynamically placed anchor

    init() {
        // Register systems - moved to setup to ensure RealityKit is ready
        // MovementSystem.registerSystem()
    }

    // Setup method called from ImmersiveView
    func setup(rootEntity: Entity, worldTracking: WorldTrackingProvider) {
        guard !isSetupComplete else {
            print("GameManager: Setup already complete.")
            return
        }
        print("GameManager: Setup running...")
        self.sceneRootEntity = rootEntity
        self.worldTrackingProvider = worldTracking
        self.isImmersiveSpaceOpen = true
        self.isSetupComplete = true

        // Register systems now that we have a RealityKit context
        MovementSystem.registerSystem()
        print("GameManager: Setup complete. Systems registered.")
    }

    // Called when the ImmersiveView disappears
    func handleDisappear() {
        print("GameManager: Handling disappear.")
        self.isImmersiveSpaceOpen = false
        // Reset game state or perform other cleanup if needed
        resetGame()
        // Clear ARKit references
        self.worldTrackingProvider = nil
        self.sceneRootEntity = nil
        self.dynamicWorldAnchor = nil
        self.isSetupComplete = false
    }

    // Start the game
    func startGame() {
        print("GameManager: startGame called.")
        guard isSetupComplete, let root = sceneRootEntity, let tracker = worldTrackingProvider else {
            print("GameManager Error: Setup not complete or ARKit components missing. Cannot start game.")
            gameState = .menu // Revert to menu if setup failed
            return
        }

        guard gameState == .menu || gameState == .gameOver else {
            print("GameManager: Game already in progress or starting.")
            return
        }

        gameState = .playing
        score = 0
        resetGameEntities()

        // --- Create Dynamic Anchor based on Head Pose ---
        guard let deviceTransform = tracker.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())?.originFromAnchorTransform else {
            print("GameManager Error: Could not get device transform. Cannot start game.")
            gameState = .menu
            return
        }

        // --- RESTORED Anchor Offset Calculation --- 
        // Calculate anchor position: 1.5m forward, 0.2m down from head
        let forwardOffset = SIMD3<Float>(0, 0, -1.5) // -Z is forward in RealityKit
        let downOffset = SIMD3<Float>(0, -0.2, 0)
        // Apply offsets in the device's local coordinate space
        var anchorTransform = deviceTransform
        let localOffset = forwardOffset + downOffset
        anchorTransform.columns.3.x += anchorTransform.columns.0.x * localOffset.x + anchorTransform.columns.1.x * localOffset.y + anchorTransform.columns.2.x * localOffset.z
        anchorTransform.columns.3.y += anchorTransform.columns.0.y * localOffset.x + anchorTransform.columns.1.y * localOffset.y + anchorTransform.columns.2.y * localOffset.z
        anchorTransform.columns.3.z += anchorTransform.columns.0.z * localOffset.x + anchorTransform.columns.1.z * localOffset.y + anchorTransform.columns.2.z * localOffset.z
        // ---------------------------------------------------------------

        // Create the anchor
        let newAnchor = AnchorEntity(world: anchorTransform)
        newAnchor.name = "DynamicWorldAnchor"
        root.addChild(newAnchor) // Add anchor to the scene's root
        self.dynamicWorldAnchor = newAnchor // Store reference

        // --- Game World Entity Setup ---
        // Create the main entity to hold all game elements
        gameWorldEntity = Entity()
        gameWorldEntity.name = "GameWorld"
        print("GameManager: gameWorldEntity created. Initial Scale: \(gameWorldEntity.scale)")
        
        // Apply the constant Y offset if needed (relative to the new anchor)
        gameWorldEntity.position.y = Constants.gameTableYOffset // Qualify constant
        newAnchor.addChild(gameWorldEntity) // IMPORTANT: Add game world as child of the NEW anchor
        
        print("GameManager: gameWorldEntity added to anchor. Scale now: \(gameWorldEntity.scale)")
        print("GameManager: Anchor scale: \(newAnchor.scale)")
        print("GameManager: Dynamic world anchor created and gameWorldEntity added as child.")
        // -------------------------------

        // Create the player entity
        // Removed incorrect @MainActor attribute - Task inherits context from @MainActor func
        Task {
            do {
                playerEntity = try await EntityFactory.createPlayerEntity()
                if let player = playerEntity {
                    player.name = "Player"
                    // Qualify constants
                    player.position = SIMD3<Float>(0, Constants.playerStartYOffset, Float(Constants.lanesToGenerate - 1) * Constants.laneWidth / 2.0) 
                    gameWorldEntity.addChild(player) // Add player to gameWorldEntity
                    print("GameManager: Player added. Scale from factory: \(player.scale)") // Log scale after adding
                    
                } else {
                    throw NSError(domain: "GameManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player entity creation returned nil"])
                }
            } catch {
                print("GameManager Error: Failed to create player entity: \(error). Setting state to gameOver.")
                resetGameEntities() // Clean up anything partially created
                gameState = .gameOver
                return // Stop further setup
            }
            
            // Generate initial lanes
            print("GameManager: Generating initial lanes...")
            for i in 0..<Constants.lanesToGenerate { // Qualify constant
                generateNextLane()
            }
            print("GameManager: Initial lanes generated.")
        }
    }

    // Reset game entities and state
    func resetGame() {
        print("GameManager: resetGame called.")
        gameState = .menu
        score = 0
        resetGameEntities()
    }

    // Clear existing entities from the scene
    private func resetGameEntities() {
        print("GameManager: resetGameEntities called.")
        playerEntity?.removeFromParent()
        playerEntity = nil
        
        for (_, lane) in activeLanes {
            lane.removeFromParent()
        }
        activeLanes.removeAll()

        for obstacle in activeObstacles {
            obstacle.removeFromParent()
        }
        activeObstacles.removeAll()
        
        // Also remove the main game world entity from its anchor
        gameWorldEntity.removeFromParent()
        // And remove the dynamic anchor itself
        dynamicWorldAnchor?.removeFromParent()
        dynamicWorldAnchor = nil

        laneIndexCounter = 0
        print("GameManager: Entities reset.")
    }

    // Generate the next lane
    private func generateNextLane() {
        guard gameWorldEntity.parent != nil else {
             print("GameManager Warning: Attempted to generate lane but gameWorldEntity has no parent (likely game not started or reset). Skipping.")
             return
         }
        let laneType = LaneType.random()
        let index = laneIndexCounter
        laneIndexCounter += 1

        Task { // This task can remain as is (doesn't need explicit @MainActor)
            do {
                print("GameManager: Creating lane entity for index \(index) of type \(laneType)")
                let laneEntity = try await EntityFactory.createLaneEntity(type: laneType, index: index)
                laneEntity.name = "Lane_\(index)"
                activeLanes[index] = laneEntity
                gameWorldEntity.addChild(laneEntity) // Add lane to gameWorldEntity
                print("GameManager: Lane \(index) added to game world.")

                // Generate obstacles for the lane
                if laneType != .grass { // Don't spawn obstacles on grass
                     // Qualify constant
                    let numberOfObstacles = Int.random(in: 1...Constants.maxObstaclesPerLane)
                    for _ in 0..<numberOfObstacles {
                         generateObstacle(forLaneIndex: index, laneType: laneType)
                    }
                }
            } catch {
                 print("GameManager Error: Failed to create lane entity for index \(index): \(error)")
                 // Consider how to handle lane creation failure - maybe stop generating?
            }
        }
    }
    
    // Generate an obstacle for a specific lane
    private func generateObstacle(forLaneIndex laneIndex: Int, laneType: LaneType) {
        guard gameWorldEntity.parent != nil else {
             print("GameManager Warning: Attempted to generate obstacle but gameWorldEntity has no parent. Skipping.")
             return
         }
        let obstacleType: ObstacleType
        switch laneType {
            case .road: obstacleType = ObstacleType.carTypes.randomElement()!
            case .water: obstacleType = .log
            default: return // Should not happen based on calling logic
        }
        
        Task { 
            do {
                 print("GameManager: Creating obstacle entity of type \(obstacleType) for lane \(laneIndex)")
                 let obstacleEntity = try await EntityFactory.createObstacleEntity(type: obstacleType, laneIndex: laneIndex)
                 obstacleEntity.name = "Obstacle_\(laneIndex)_\(obstacleType)"
                 activeObstacles.insert(obstacleEntity)
                 gameWorldEntity.addChild(obstacleEntity) // Add obstacle to gameWorldEntity
                 print("GameManager: Obstacle \(obstacleType) added. Scale from factory: \(obstacleEntity.scale)") // Log scale after adding

            } catch {
                 print("GameManager Error: Failed to create obstacle entity \(obstacleType) for lane \(laneIndex): \(error)")
            }
        }
    }

    // Handle player input (e.g., tap to move forward)
    func handleTap(on entity: Entity) {
        guard gameState == .playing, let player = playerEntity else { return }
        
        print("GameManager: Handle tap received on entity: \(entity.name ?? "Unknown")")
        
        // Example: Simple move forward on any tap for now
        // TODO: Implement proper directional movement based on tap location or gesture
        movePlayer(direction: .forward)
    }
    
    // Move the player
    func movePlayer(direction: MoveDirection) {
        guard gameState == .playing, let player = playerEntity else { return }

        var targetPosition = player.position(relativeTo: gameWorldEntity) // Move relative to game world
        let moveDistance = Constants.laneWidth // Qualify constant

        switch direction {
        case .forward:
            targetPosition.z -= moveDistance
        case .backward:
             targetPosition.z += moveDistance
        // case .left: // TODO
        //     targetPosition.x -= moveDistance
        // case .right: // TODO
        }
        
        print("GameManager: Moving player from \(player.position(relativeTo: gameWorldEntity)) to \(targetPosition)")

        // Animate the movement - ONLY change translation
        var transform = player.transform
        transform.translation = targetPosition
        // Qualify constant
        player.move(to: transform, relativeTo: gameWorldEntity, duration: Constants.playerMoveDuration, timingFunction: .easeInOut)
        
        // Update score if moved forward
        if direction == .forward {
             // Qualify constant
            let currentLaneIndex = Int(round((player.position.z / Constants.laneWidth) * -1))
            score = max(score, currentLaneIndex)
            print("GameManager: Player moved forward. Current Approx Lane Index: \(currentLaneIndex), Score: \(score)")
            // Check if we need to generate a new lane
            // Qualify constant
            if currentLaneIndex > laneIndexCounter - Constants.lanesAheadToGenerate {
                print("GameManager: Player approaching edge, generating new lane.")
                generateNextLane()
                // TODO: Remove distant lanes behind the player
            }
        }
        
        // TODO: Collision Detection
        // checkCollisions()
    }
    
    // --- Placeholder for collision checks ---
    private func checkCollisions() {
         guard let player = playerEntity else { return }
         let playerBounds = player.visualBounds(relativeTo: gameWorldEntity)

         for obstacle in activeObstacles {
             let obstacleBounds = obstacle.visualBounds(relativeTo: gameWorldEntity)
             if playerBounds.intersects(obstacleBounds) {
                print("Collision detected with obstacle: \(obstacle.name ?? "Unknown")")
                gameOver()
                return
            }
        }
        
        // Check if player fell in water (conceptual)
        // Need logic to determine if player's Z position corresponds to a water lane
        // AND if they are *not* on a log at that Z position.
        // let currentLaneIndex = ...
        // if activeLanes[currentLaneIndex]?.laneType == .water && !isOnLog(position: player.position) {
        //     gameOver()
        // }
    }
    
    // --- Placeholder: Check if position is on a log ---
    private func isOnLog(position: SIMD3<Float>) -> Bool {
        // TODO: Implement check against log obstacle positions/bounds at the player's Z coord
        return false
    }
    
    // Game over logic
    private func gameOver() {
        print("GameManager: Game Over! Score: \(score)")
        gameState = .gameOver
        // TODO: Add game over effects or UI updates
    }
    
}

// Enum for player movement directions
enum MoveDirection {
    case forward, backward // , left, right
} 