import SwiftUI
import RealityKit

enum Constants {
    // MARK: - Game Parameters
    static let laneWidth: Float = 0.5        // Width of a single lane
    static let laneSegments = 10             // How many segments make up lane width (for texture tiling etc)
    static let laneSegmentWidth: Float = laneWidth / Float(laneSegments)
    static let gameTableYOffset: Float = 0.001 // Tiny offset to prevent Z-fighting with world anchor origin
    static let maxObstaclesPerLane = 3       // Max obstacles on a road/water lane
    static let lanesToGenerate = 10          // Initial number of lanes to generate
    static let lanesAheadToGenerate = 5      // How many lanes ahead of the player to maintain

    // MARK: - Player Parameters
    static let playerModelName = "chicken.usdz" // Placeholder model
    static let playerScale: Float = 0.1 / 100.0  // Corrected scale (assuming cm export)
    static let playerStartPosition: SIMD3<Float> = [0, 0.0, 0] // Will be adjusted by GameManager
    static let playerStartYOffset: Float = 0.02    // Small Y offset when placing player on lane
    static let playerMoveDuration: TimeInterval = 0.2 // Animation duration

    // MARK: - Obstacle Parameters
    static let carModelName = "car_blue.usdz" // Placeholder
    static let logModelName = "log.usdz"      // Placeholder
    static let trainModelName = "train.usdz"    // Placeholder
    static let obstacleScale: Float = 0.15 / 100.0 // Corrected scale (assuming cm export)
    static let obstacleYOffset: Float = 0.01    // Slight offset for obstacles
    static let defaultCarSpeed: Float = 0.6      // Base speed (m/s)
    static let defaultLogSpeed: Float = 0.4      // Base speed (m/s)
    static let defaultTrainSpeed: Float = 2.0    // Base speed (m/s)
    static let spawnEdgeDistance: Float = 3.0   // How far offscreen obstacles spawn (X-axis)
    static let obstacleSpawnInterval: TimeInterval = 1.5 // Average time between spawns

    // Movement directions (assuming +X is right, -Z is forward relative to game world)
    static let forwardDirection: SIMD3<Float> = [0, 0, -1]
    static let backwardDirection: SIMD3<Float> = [0, 0, 1]
    static let leftDirection: SIMD3<Float> = [-1, 0, 0]
    static let rightDirection: SIMD3<Float> = [1, 0, 0]

    // MARK: - Lane Models
    static let grassLaneModelName = "grass_lane.usdz"
    static let roadLaneModelName = "road_lane.usdz"
    static let waterLaneModelName = "water_lane.usdz"
    static let trainTrackLaneModelName = "train_track_lane.usdz"
    static let laneScale: Float = 1.0 / 1000.0 // Corrected scale (assuming cm export AND further adjustment)

} 