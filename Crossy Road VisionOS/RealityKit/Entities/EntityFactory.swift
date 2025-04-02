// Functions to create player, obstacles, lanes
import RealityKit
import Foundation
import SwiftUI // Keep for potential future color use or if Constants uses it

@MainActor // Ensure functions run on the main actor if they modify the scene graph directly
enum EntityFactory {

    static func createPlayerEntity() async throws -> ModelEntity {
        let playerEntity = try await ModelEntity(named: Constants.playerModelName)
        playerEntity.name = "Player"
        playerEntity.scale = SIMD3<Float>(repeating: Constants.playerScale)
        playerEntity.generateCollisionShapes(recursive: true) // Generate collision
        playerEntity.components.set(InputTargetComponent()) // Allow gestures to target it
        playerEntity.components.set(PlayerComponent()) // Add player logic component
        // Position is now set by GameManager
        // playerEntity.transform.translation = Constants.playerStartPosition 

        print("Player entity created")
        return playerEntity
    }

    static func createLaneEntity(type: LaneType, index: Int) async throws -> Entity {
        let laneEntity = Entity() // Use a base entity to hold the model and component
        laneEntity.name = "Lane_\(index)"
        laneEntity.components.set(LaneComponent(type: type, index: index))

        let modelName: String
        switch type {
        case .grass: modelName = Constants.grassLaneModelName
        case .road: modelName = Constants.roadLaneModelName
        case .water: modelName = Constants.waterLaneModelName
        }

        do {
            let laneModel = try await ModelEntity(named: modelName)
            laneModel.name = "LaneModel_\(index)"
            
            // Apply the scale
            laneModel.scale = SIMD3<Float>(repeating: Constants.laneScale)
            
            // Position the model correctly within the lane entity
            let centerOffset = -Float(Constants.laneSegments / 2) * Constants.laneSegmentWidth + Constants.laneSegmentWidth / 2
            laneModel.position.x = centerOffset
            laneModel.position.z = -Float(index) * Constants.laneWidth // Position based on index
            
            laneEntity.addChild(laneModel)
            print("Lane entity created: \(type) at index \(index)")

        } catch {
             print("Error loading model \(modelName): \(error)")
             throw error // Re-throw error
        }

        return laneEntity
    }

    static func createObstacleEntity(type: ObstacleType, laneIndex: Int) async throws -> ModelEntity {
        let modelName: String
        var speed = Constants.defaultCarSpeed
        let direction: SIMD3<Float> = (laneIndex % 2 == 0) ? Constants.leftDirection : Constants.rightDirection // Alternate direction

        switch type {
        case .car:
            modelName = Constants.carModelName
        case .log:
            modelName = Constants.logModelName
            speed = Constants.defaultLogSpeed
        case .train:
            modelName = Constants.trainModelName
            speed = Constants.defaultTrainSpeed
        }

        let obstacleEntity = try await ModelEntity(named: modelName)
        obstacleEntity.name = "\(type)_\(UUID().uuidString)" // Unique name
        obstacleEntity.scale = SIMD3<Float>(repeating: Constants.obstacleScale)
        obstacleEntity.generateCollisionShapes(recursive: true)
        obstacleEntity.components.set(ObstacleComponent(type: type, speed: speed, direction: direction))

        print("Obstacle entity created: \(type)")
        return obstacleEntity
    }
}
