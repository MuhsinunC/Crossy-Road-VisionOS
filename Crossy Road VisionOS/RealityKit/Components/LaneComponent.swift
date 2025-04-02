// Identifies a lane type
import RealityKit

struct LaneComponent: Component, Codable {
    // REMOVED Enum Definition - Now defined globally in LaneType.swift
    // enum LaneType: Codable {
    //    case grass, road, water, trainTrack
    // }

    var type: LaneType // Uses the global LaneType now
    var index: Int // The row index of this lane
} 