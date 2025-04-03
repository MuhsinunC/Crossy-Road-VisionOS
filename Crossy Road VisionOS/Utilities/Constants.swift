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

    // MARK: - Player Parameters (Non-model specific)
    static let playerStartPosition: SIMD3<Float> = [0, 0.0, 0] // Initial offset relative to game world anchor
    static let playerStartYOffset: Float = 0.02    // Small Y offset when placing player on lane
    static let playerMoveDuration: TimeInterval = 0.2 // Animation duration

    // MARK: - Obstacle Parameters (Non-model specific)
    static let obstacleYOffset: Float = 0.01    // Slight offset for obstacles
    static let defaultCarSpeed: Float = 0.6      // Base speed (m/s)
    static let defaultLogSpeed: Float = 0.4      // Base speed (m/s)
    static let defaultTrainSpeed: Float = 2.0    // Base speed (m/s) - Not used
    static let spawnEdgeDistance: Float = 3.0   // How far offscreen obstacles spawn (X-axis)
    static let obstacleSpawnInterval: TimeInterval = 1.5 // Average time between spawns

    // Movement directions (assuming +X is right, -Z is forward relative to game world)
    static let forwardDirection: SIMD3<Float> = [0, 0, -1]
    static let backwardDirection: SIMD3<Float> = [0, 0, 1]
    static let leftDirection: SIMD3<Float> = [-1, 0, 0]
    static let rightDirection: SIMD3<Float> = [1, 0, 0]

    // MARK: - Model Properties (MOVED TO ModelCatalog.swift)
    // Removed definitions for: player, carBlue, log, grassLane, roadLane, waterLane
    
} 