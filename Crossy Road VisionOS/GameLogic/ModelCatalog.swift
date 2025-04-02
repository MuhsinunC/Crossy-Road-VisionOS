import RealityKit
import simd

/// A catalog containing pre-configured properties for all game models.
enum ModelCatalog {

    // MARK: - Player Model Properties
    static let player: ModelProperties = ModelProperties(
        fileName: "chicken.usdz", 
        scale: 0.1 / 100.0, // Corrected scale (assuming cm export)
        // rotationDegreesX: 0, // Default
        rotationDegreesY: -90.0, // Rotate -90 degrees around Y
        // rotationDegreesZ: 0 // Default
    )
    
    // MARK: - Obstacle Model Properties
    static let carBlue: ModelProperties = ModelProperties(
        fileName: "car_blue.usdz", 
        scale: 0.15 / 100.0 // Corrected scale (assuming cm export)
        // Default 0 degree rotation for all axes
    )
    static let log: ModelProperties = ModelProperties(
        fileName: "log.usdz", 
        scale: 0.15 / 100.0 // Corrected scale (assuming cm export)
        // Default 0 degree rotation for all axes
    )
    // Placeholder for potential train model
    // static let train: ModelProperties = ModelProperties(fileName: "train.usdz", scale: 0.2 / 100.0)
    
    // MARK: - Lane Model Properties
    static let grassLane: ModelProperties = ModelProperties(
        fileName: "grass_lane.usdz", 
        scale: 1.0 / 1000.0, // Corrected scale
        rotationDegreesY: -25.0, // Rotate -25 degrees around Y
        offset: [0, 0.25, 0] // Raise by 10 inches (0.254 meters)
    )
    static let roadLane: ModelProperties = ModelProperties(
        fileName: "road_lane.usdz",
        scale: 1.0 / 1000.0, // Corrected scale
        rotationDegreesY: 270.0, // Rotate 270 degrees around Y
        offset: [0, -0.17, 0]
    )
    static let waterLane: ModelProperties = ModelProperties(
        fileName: "water_lane.usdz", 
        scale: (0.5 / 1000.0),
        offset: [0.4, 0, 0]
    )
} 