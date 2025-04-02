# System to update obstacle positions
import RealityKit

// A system processes entities with specific components each frame.
struct MovementSystem: System {

    static let query = EntityQuery(where: .has(ObstacleComponent.self))

    init(scene: Scene) {
        // Initialization if needed (e.g., getting references)
    }

    func update(context: SceneUpdateContext) {
        // This runs every frame/simulation tick
        let deltaTime = Float(context.deltaTime)

        context.scene.performQuery(Self.query).forEach { entity in
            guard var obstacle = entity.components[ObstacleComponent.self],
                  var transform = entity.components[Transform.self] else {
                return
            }

            // Calculate movement
            let movement = obstacle.direction * obstacle.speed * deltaTime
            transform.translation += movement

            // Update the entity's transform component
            entity.components.set(transform)

            // TODO: Add despawning logic here
            // Check if entity is out of bounds (e.g., based on distance from player or anchor)
            // if isOutOfBounds(entity.position) {
            //    entity.removeFromParent()
            // }
        }
    }
}
