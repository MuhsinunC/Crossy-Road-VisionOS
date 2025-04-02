// Logic specific to the player character
import RealityKit
import Foundation // Needed for UUID

struct PlayerComponent: Component, Codable {
    var isAlive: Bool = true
    var currentLaneIndex: Int = 0 // Track which lane the player is in
    // Add other player-specific state if needed (e.g., character type)
}
