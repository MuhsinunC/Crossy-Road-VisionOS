// Functions to create player, obstacles, lanes
import RealityKit
import Foundation
import SwiftUI // Keep for potential future color use or if Constants uses it

@MainActor // Ensure functions run on the main actor if they modify the scene graph directly
enum EntityFactory {

    static func createPlayerEntity() async throws -> ModelEntity {
        // Use ModelProperties from ModelCatalog
        let properties = ModelCatalog.player
        let playerEntity = try await ModelEntity(named: properties.fileName)
        playerEntity.name = "Player"
        playerEntity.scale = properties.scale
        playerEntity.orientation = properties.rotation
        playerEntity.position = properties.offset // Apply offset
        playerEntity.generateCollisionShapes(recursive: true)
        playerEntity.components.set(InputTargetComponent())
        playerEntity.components.set(PlayerComponent())
        
        print("Player entity created using properties from ModelCatalog")
        return playerEntity
    }

    static func createLaneEntity(type: LaneType, index: Int) async throws -> Entity {
        let laneEntity = Entity()
        laneEntity.name = "Lane_\(index)"
        laneEntity.components.set(LaneComponent(type: type, index: index))

        // Use ModelProperties from ModelCatalog
        let properties: ModelProperties
        switch type {
        case .grass: properties = ModelCatalog.grassLane
        case .road: properties = ModelCatalog.roadLane
        case .water: properties = ModelCatalog.waterLane
        // No trainTrack case
        }

        do {
            let laneModel = try await ModelEntity(named: properties.fileName)
            laneModel.name = "LaneModel_\(index)"
            
            // Apply scale and rotation from properties
            laneModel.scale = properties.scale
            laneModel.orientation = properties.rotation
            
            // Base position calculation
            let centerOffset = -Float(Constants.laneSegments / 2) * Constants.laneSegmentWidth + Constants.laneSegmentWidth / 2
            var modelPosition = SIMD3<Float>.zero
            modelPosition.x = centerOffset
            modelPosition.z = -Float(index) * Constants.laneWidth // Position based on index
            
            // Apply additional offset from properties
            modelPosition += properties.offset 
            laneModel.position = modelPosition
            
            laneEntity.addChild(laneModel)
            print("Lane entity created: \(type) at index \(index) using properties from ModelCatalog")

        } catch {
             print("Error loading model \(properties.fileName): \(error)")
             throw error // Re-throw error
        }

        return laneEntity
    }

    static func createObstacleEntity(type: ObstacleType, laneIndex: Int) async throws -> ModelEntity {
        
        // Use ModelProperties from ModelCatalog
        let properties: ModelProperties
        var speed: Float
        switch type {
        case .car:
            properties = ModelCatalog.carBlue // Use the specific car property
            speed = Constants.defaultCarSpeed
        case .log:
            properties = ModelCatalog.log
            speed = Constants.defaultLogSpeed
        case .train: // Keep case for potential future re-addition, but return error for now
            print("Error: Train obstacle type is not currently supported.")
            throw NSError(domain: "EntityFactory", code: 100, userInfo: [NSLocalizedDescriptionKey: "Train obstacle type not supported"]) 
            // properties = ModelCatalog.train 
            // speed = Constants.defaultTrainSpeed
        }

        let obstacleEntity = try await ModelEntity(named: properties.fileName)
        obstacleEntity.name = "\(type)_\(UUID().uuidString)" // Unique name
        // Apply scale and rotation from properties
        obstacleEntity.scale = properties.scale
        obstacleEntity.orientation = properties.rotation
        obstacleEntity.position = properties.offset // Apply offset
        obstacleEntity.generateCollisionShapes(recursive: true)
        
        let direction: SIMD3<Float> = (laneIndex % 2 == 0) ? Constants.leftDirection : Constants.rightDirection // Alternate direction
        obstacleEntity.components.set(ObstacleComponent(type: type, speed: speed, direction: direction))

        print("Obstacle entity created: \(type) using properties from ModelCatalog")
        return obstacleEntity
    }
}
