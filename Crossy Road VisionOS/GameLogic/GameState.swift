// Enum for different game states
import Foundation

enum GameState {
    case setup       // Initializing, waiting for plane anchor
    case placing     // Plane found, user confirms placement (optional step)
    case ready       // Game placed, ready to start
    case playing     // Game is active
    case gameOver    // Player lost
} 