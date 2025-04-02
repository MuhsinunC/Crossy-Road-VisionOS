import Foundation // Needed for random functions

// Definition of Lane Types

enum LaneType: Codable, CaseIterable {
    case grass, road, water

    // Static function to get a random lane type
    static func random() -> LaneType {
        // Simple random selection for now (excluding trainTrack)
        // You could add weights or patterns later
        let validCases = LaneType.allCases // Now doesn't include trainTrack
        return validCases.randomElement() ?? .grass // Default to grass if something goes wrong
    }
} 