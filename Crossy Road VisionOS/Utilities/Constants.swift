// Game constants (speed, sizes, etc.)
import Foundation
import RealityKit // For SIMD types if needed

enum Constants {
    // Sizes & Positions
    static let laneWidth: Float = 0.4 // Width/depth of a lane in meters
    static let playerStartPosition: SIMD3<Float> = [0, 0.01, 0] // Start slightly above the anchor
    // static let playerScale: SIMD3<Float> = [0.05, 0.05, 0.05] // Adjust scale as needed
    // static let laneScale: SIMD3<Float> = [1, 1, 1] // Assuming models are pre-scaled
    // static let obstacleScale: SIMD3<Float> = [0.06, 0.06, 0.06] // Adjust scale
    static let playerScale: Float = 0.01     // Uniform scale factor for the player
    static let laneScale: Float = 0.01        // Uniform scale factor for lanes (adjust as needed)
    static let obstacleScale: Float = 0.01   // Uniform scale factor for obstacles (adjust as needed)
    static let obstacleYOffset: Float = 0.01 // Slight vertical offset for obstacles if needed
    static let minTableSize: Float = 0.5 // Minimum width/height of detected table plane in meters


    // Movement & Timing
    static let playerMoveDuration: TimeInterval = 0.15 // Seconds for hop animation
    static let defaultCarSpeed: Float = 0.6 // Meters per second
    static let defaultLogSpeed: Float = 0.4 // Meters per second
    static let defaultTrainSpeed: Float = 1.5 // Meters per second
    static let obstacleSpawnInterval: TimeInterval = 1.2 // Seconds between spawns
    static let spawnEdgeDistance: Float = 2.0 // How far off-screen (X-axis) obstacles spawn


    // Directions (relative to forward Z-)
    static let forwardDirection: SIMD3<Float> = [0, 0, -1]
    static let backwardDirection: SIMD3<Float> = [0, 0, 1]
    static let leftDirection: SIMD3<Float> = [-1, 0, 0]
    static let rightDirection: SIMD3<Float> = [1, 0, 0]

    // Asset Names (ensure these match your files)
    static let playerModelName = "chicken.usdz"
    static let carModelName = "car_blue.usdz" // Use specific names or choose randomly later
    static let logModelName = "log.usdz"
    static let treeModelName = "tree.usdz" // Example, not used in code yet
    static let grassLaneModelName = "grass_lane.usdz"
    static let roadLaneModelName = "road_lane.usdz"
    static let waterLaneModelName = "water_lane.usdz"
    static let trainTrackLaneModelName = "train_track_lane.usdz" // Placeholder name
    static let trainModelName = "train.usdz" // Placeholder name

} 