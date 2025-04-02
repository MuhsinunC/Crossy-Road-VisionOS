# Identifies a lane type
import RealityKit

struct LaneComponent: Component, Codable {
    enum LaneType: Codable {
        case grass, road, water, trainTrack
    }

    var type: LaneType
    var index: Int // The row index of this lane
} 