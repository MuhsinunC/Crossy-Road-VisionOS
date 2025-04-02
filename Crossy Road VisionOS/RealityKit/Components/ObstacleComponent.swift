// Logic for moving obstacles (cars, logs)
import RealityKit
import simd // For vector types like SIMD3

struct ObstacleComponent: Component, Codable {
    var type: ObstacleType // Uses the global ObstacleType now
    var speed: Float // Units per second
    var direction: SIMD3<Float> // Movement direction relative to the lane

    // Add timer or distance tracking for despawning if needed
} 