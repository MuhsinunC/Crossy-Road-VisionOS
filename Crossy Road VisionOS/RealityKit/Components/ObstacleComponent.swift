# Logic for moving obstacles (cars, logs)
import RealityKit
import simd // For vector types like SIMD3

struct ObstacleComponent: Component, Codable {
    enum ObstacleType: Codable {
        case car, log, train // Add more as needed
    }

    var type: ObstacleType
    var speed: Float // Units per second
    var direction: SIMD3<Float> // Movement direction relative to the lane

    // Add timer or distance tracking for despawning if needed
} 