// Definition of Obstacle Types
import simd // For potential future use if associated values need it

enum ObstacleType: Codable {
    case car, log, train // Add more as needed

    // Helper property to get car types easily if needed elsewhere
    static var carTypes: [ObstacleType] {
        return [.car] // Extend this if you add more car types (e.g., .truck)
    }
} 