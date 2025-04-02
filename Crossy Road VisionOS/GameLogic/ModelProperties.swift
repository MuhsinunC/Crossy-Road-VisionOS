import RealityKit
import simd

/// Structure to hold configuration properties for a specific 3D model.
struct ModelProperties {
    let fileName: String
    let scale: SIMD3<Float>
    let rotation: simd_quatf

    /// Private helper to convert degrees to radians
    private static func degreesToRadians(_ degrees: Float) -> Float {
        return (degrees * .pi) / 180.0
    }

    /// Initializer with uniform scale and optional Y-axis rotation in DEGREES.
    init(fileName: String, scale: Float, rotationDegreesY: Float = 0) {
        self.fileName = fileName
        self.scale = SIMD3<Float>(repeating: scale)
        let radians = ModelProperties.degreesToRadians(rotationDegreesY)
        self.rotation = simd_quatf(angle: radians, axis: [0, 1, 0])
    }
    
    /// Initializer allowing non-uniform scale and optional Y-axis rotation in DEGREES.
    init(fileName: String, scale: SIMD3<Float>, rotationDegreesY: Float = 0) {
        self.fileName = fileName
        self.scale = scale
        let radians = ModelProperties.degreesToRadians(rotationDegreesY)
        self.rotation = simd_quatf(angle: radians, axis: [0, 1, 0])
    }
    
    /// Initializer allowing uniform scale and explicit rotation quaternion.
    init(fileName: String, scale: Float, rotation: simd_quatf) {
        self.fileName = fileName
        self.scale = SIMD3<Float>(repeating: scale)
        self.rotation = rotation
    }
    
    /// Initializer allowing non-uniform scale and explicit rotation quaternion.
    init(fileName: String, scale: SIMD3<Float>, rotation: simd_quatf) {
        self.fileName = fileName
        self.scale = scale
        self.rotation = rotation
    }
} 