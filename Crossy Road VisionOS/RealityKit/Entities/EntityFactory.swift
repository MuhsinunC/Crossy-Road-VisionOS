# Functions to create player, obstacles, lanes
import RealityKit
import Foundation

@MainActor // Ensure functions run on the main actor if they modify the scene graph directly
enum EntityFactory {

    static func createPlayerEntity() async throws -> ModelEntity {
        let playerEntity = try await ModelEntity(named: Constants.playerModelName)
        playerEntity.name = "Player"
        playerEntity.generateCollisionShapes(recursive: true) // Generate collision
        playerEntity.components.set(InputTargetComponent()) // Allow gestures to target it
        playerEntity.components.set(PlayerComponent()) // Add player logic component
        playerEntity.transform.translation = Constants.playerStartPosition // Set initial position
        playerEntity.transform.scale = Constants.playerScale // Set scale

        print("Player entity created")
        return playerEntity
    }

    static func createLaneEntity(type: LaneComponent.LaneType, index: Int) async throws -> Entity {
        let laneEntity = Entity() // Use a base entity to hold the model and component
        laneEntity.name = "Lane_\(index)"
        laneEntity.components.set(LaneComponent(type: type, index: index))

        let modelName: String
        switch type {
        case .grass: modelName = Constants.grassLaneModelName
        case .road: modelName = Constants.roadLaneModelName
        case .water: modelName = Constants.waterLaneModelName
        case .trainTrack: modelName = Constants.trainTrackLaneModelName // Assuming you have this model
        }

        do {
            let laneModel = try await ModelEntity(named: modelName)
            laneModel.name = "LaneModel_\(index)"
            // No collision needed for the lane itself usually, unless it's a trigger
            laneModel.transform.scale = Constants.laneScale
            laneEntity.addChild(laneModel)

            // Position will be set by GameManager when placing the lane
            print("Lane entity created: \(type) at index \(index)")

        } catch {
             print("Error loading model \(modelName): \(error)")
             throw error // Re-throw error
        }


        return laneEntity
    }

    static func createObstacleEntity(type: ObstacleComponent.ObstacleType, laneIndex: Int) async throws -> ModelEntity {
        let modelName: String
        var speed = Constants.defaultCarSpeed
        let direction: SIMD3<Float> = (laneIndex % 2 == 0) ? Constants.leftDirection : Constants.rightDirection // Alternate direction

        switch type {
        case .car:
            // Maybe choose a random car model?
            modelName = Constants.carModelName // Assume one for now
        case .log:
            modelName = Constants.logModelName
            speed = Constants.defaultLogSpeed
        case .train:
            modelName = Constants.trainModelName // Assuming model exists
            speed = Constants.defaultTrainSpeed
        }

        let obstacleEntity = try await ModelEntity(named: modelName)
        obstacleEntity.name = "\(type)_\(UUID().uuidString)" // Unique name
        obstacleEntity.generateCollisionShapes(recursive: true)
        // Obstacles usually don't need InputTargetComponent unless you want to tap them
        obstacleEntity.components.set(ObstacleComponent(type: type, speed: speed, direction: direction))
        obstacleEntity.transform.scale = Constants.obstacleScale // Adjust scale as needed

        print("Obstacle entity created: \(type)")
        return obstacleEntity
    }
}
