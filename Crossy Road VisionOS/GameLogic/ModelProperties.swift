import RealityKit
import simd

/// Structure to hold configuration properties for a specific 3D model.
struct ModelProperties {
    let fileName: String
    let scale: SIMD3<Float>
    let rotation: simd_quatf
    let offset: SIMD3<Float>

    /// Private helper to convert degrees to radians
    private static func degreesToRadians(_ degrees: Float) -> Float {
        return (degrees * .pi) / 180.0
    }

    /// Initializer with uniform scale and optional X, Y, Z rotation in DEGREES and optional offset.
    init(fileName: String, 
         scale: Float, 
         rotationDegreesX: Float = 0, 
         rotationDegreesY: Float = 0, 
         rotationDegreesZ: Float = 0,
         offset: SIMD3<Float> = .zero) {
        self.fileName = fileName
        self.scale = SIMD3<Float>(repeating: scale)
        self.offset = offset
        
        // Create individual quaternions for each axis
        let radX = ModelProperties.degreesToRadians(rotationDegreesX)
        let radY = ModelProperties.degreesToRadians(rotationDegreesY)
        let radZ = ModelProperties.degreesToRadians(rotationDegreesZ)
        
        let quatX = simd_quatf(angle: radX, axis: [1, 0, 0])
        let quatY = simd_quatf(angle: radY, axis: [0, 1, 0])
        let quatZ = simd_quatf(angle: radZ, axis: [0, 0, 1])
        
        // Combine rotations (order ZYX is common: apply Z, then Y, then X)
        self.rotation = quatZ * quatY * quatX
    }
    
    /// Initializer allowing non-uniform scale and optional X, Y, Z rotation in DEGREES and optional offset.
    init(fileName: String, 
         scale: SIMD3<Float>, 
         rotationDegreesX: Float = 0, 
         rotationDegreesY: Float = 0, 
         rotationDegreesZ: Float = 0,
         offset: SIMD3<Float> = .zero) {
        self.fileName = fileName
        self.scale = scale
        self.offset = offset
        
        // Create individual quaternions for each axis
        let radX = ModelProperties.degreesToRadians(rotationDegreesX)
        let radY = ModelProperties.degreesToRadians(rotationDegreesY)
        let radZ = ModelProperties.degreesToRadians(rotationDegreesZ)
        
        let quatX = simd_quatf(angle: radX, axis: [1, 0, 0])
        let quatY = simd_quatf(angle: radY, axis: [0, 1, 0])
        let quatZ = simd_quatf(angle: radZ, axis: [0, 0, 1])
        
        // Combine rotations (order ZYX)
        self.rotation = quatZ * quatY * quatX
    }
    
    /// Initializer allowing uniform scale and explicit rotation quaternion and optional offset.
    init(fileName: String, 
         scale: Float, 
         rotation: simd_quatf,
         offset: SIMD3<Float> = .zero) {
        self.fileName = fileName
        self.scale = SIMD3<Float>(repeating: scale)
        self.rotation = rotation
        self.offset = offset
    }
    
    /// Initializer allowing non-uniform scale and explicit rotation quaternion and optional offset.
    init(fileName: String, 
         scale: SIMD3<Float>, 
         rotation: simd_quatf,
         offset: SIMD3<Float> = .zero) {
        self.fileName = fileName
        self.scale = scale
        self.rotation = rotation
        self.offset = offset
    }
} 