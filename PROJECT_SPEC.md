# Project Specification: Crossy Road visionOS

## 1. Overview

This document outlines the specifications for creating a "Crossy Road" style game designed to run on Apple Vision Pro using visionOS. The game will leverage spatial computing capabilities to anchor the game world onto a physical horizontal surface, such as a table, providing an immersive mixed-reality experience. Players will navigate a character across procedurally generated lanes (roads, grass, water) while avoiding obstacles.

## 2. Target Platform

-   **Operating System:** visionOS
-   **Device:** Apple Vision Pro

## 3. Core Technologies

-   **ARKit:** For understanding the real-world environment.
    -   `PlaneDetectionProvider`: To identify horizontal surfaces (specifically tables).
    -   `WorldTrackingProvider`: To maintain stable tracking of the device relative to the physical world.
    -   *(Potential)* `HandTrackingProvider`: If more complex gestures beyond tap/pinch are explored later.
-   **RealityKit:** For 3D scene management, rendering, physics, and anchoring.
    -   `AnchorEntity`: To attach the virtual game world to the detected physical plane.
    -   Entity Component System (ECS): To define game objects (character, obstacles, lanes) and their behaviors.
    -   `ModelComponent`: For loading and displaying 3D assets.
    -   `Transform`: For positioning, rotating, and scaling entities.
    -   `CollisionComponent` & Physics Simulation: For detecting interactions between the player character and obstacles/terrain.
    -   Asset Loading: Primarily targeting USDZ format.
-   **SwiftUI:** For the main application structure, 2D UI overlays (score, menus), and potentially some interaction handling.
    -   `RealityView`: To host the RealityKit scene within the SwiftUI hierarchy.
    -   Attachments: To display SwiftUI views contextually within or near the 3D scene.
-   **Swift:** The primary programming language for implementing game logic, custom components, and application flow.

## 4. Core Concepts

-   **Spatial Anchoring:** The game world must be reliably anchored to a detected horizontal physical surface (e.g., a table). The game elements should appear fixed to this surface as the user moves.
-   **Procedural Generation:** The game environment (lanes of road, grass, water) will be generated dynamically and infinitely as the player progresses forward. Off-screen lanes behind the player will be removed to manage resources.
-   **Entity Component System (ECS):** Game objects (player character, vehicles, logs, trees, lane segments) will be implemented as RealityKit Entities. Their appearance, state, and behavior will be managed through attached Components (e.g., `ModelComponent`, `CollisionComponent`, custom Swift components for movement logic).
-   **Spatial Input (Look + Tap):** The primary control method will be visionOS's standard indirect input: the user looks at the target square (forward, left, or right relative to the character) and performs a tap gesture (index finger to thumb) to command the character to hop to that square.
-   **Collision Detection:** The system must detect collisions between the player character and obstacles (e.g., cars) and specific terrain types (e.g., water) to trigger game-over conditions. It must also detect safe landings (e.g., on grass, logs).
-   **Grid-Based Movement:** Player movement will be constrained to a grid aligned with the game lanes. Each tap input translates to a hop to an adjacent grid square.

## 5. Game Features

-   **Player Character:**
    -   A controllable character (e.g., a chicken).
    -   Movement: Hops forward, left, and right on a grid based on player input.
    -   Animation: Simple hop animation on movement.
    -   Collision: Detects collisions with obstacles and terrain.
-   **Environment Lanes:**
    -   Types: Grass (safe), Road (danger zone with cars), Water (danger zone with logs/safe spots. Landing in water is game over).
    -   Generation: Procedurally generated in rows extending forward from the player's starting point. Old rows are removed as new ones appear. Rows fly towards the player at an increasing speed relative to the player's progress.
    -   Appearance: Distinct visual appearance for each lane type using 3D models/textures.
-   **Obstacles:**
    -   Types: Vehicles (on roads), Logs (on water). Potentially Trees/static obstacles (on grass).
    -   Movement: Vehicles move horizontally across road lanes at varying speeds. Logs move horizontally across water lanes. If a player lands on a log, the log will carry the player along with it.
    -   Spawning/Despawning: Objects spawn at the edge of the flat surface (table/game area) where the game is anchored. They spawn in the air and fall to the surface with an animation. Objects despawn when they reach the other end of the game area by falling off the edge and then are removed from the scene.
    -   Collision: Trigger game over if the player collides with a vehicle or falls into water (misses a log). Logs act as safe platforms on water.
-   **Scoring:**
    -   The score increases as the player successfully moves forward (e.g., score equals the maximum forward distance reached). Moving sideways does not impact the score.
    -   Display: Score prominently displayed using a SwiftUI overlay or 3D text in the scene.
-   **Game States:**
    -   `MainMenu`: Initial state, possibly showing instructions or a start button.
    -   `Playing`: Active gameplay state.
    -   `GameOver`: State reached upon collision with a deadly obstacle or falling into water. Displays final score and offers a restart option.
-   **Sound Effects:**
    -   Hop sound
    -   Splash sound (falling in water)
    -   Crash sound (hit by car)
    -   Background music/ambience (nature sounds)
    -   Sound for car driving by
    -   Sound for log moving across river

## 6. Architecture and Structure

-   **Project Setup:** Standard visionOS App project created in Xcode.
-   **Main App (`CrossyRoadApp.swift`):** Sets up the main SwiftUI WindowGroup or ImmersiveSpace.
-   **Main View (`ContentView.swift` or similar):** Contains the SwiftUI layout, including the `RealityView` that hosts the game scene. Manages overall game state transitions (Menu -> Playing -> Game Over).
-   **RealityKit Scene (`GameScene` or similar):**
    -   Manages the root `AnchorEntity` attached to the physical plane.
    -   Handles the setup of the initial game world.
    -   Contains systems or logic for managing game entities.
-   **Game Logic Manager (`GameManager.swift` or similar):**
    -   Oversees game state.
    -   Manages scoring.
    -   Coordinates procedural generation, spawning, and despawning.
-   **Entities and Components:**
    -   Separate Swift files for custom RealityKit Components (e.g., `PlayerMovementComponent.swift`, `CarMovementComponent.swift`, `ProceduralLaneComponent.swift`).
    -   Potentially factory/helper functions or classes to create pre-configured Entities (e.g., `EntityFactory.swift`).
-   **Input Handling:** Logic to interpret ARKit/RealityKit input events (taps targeted via gaze) and translate them into actions within the `PlayerMovementComponent`.
-   **Asset Management:** 3D models (USDZ) organized likely within the main app bundle or a dedicated asset catalog/folder.

## 7. Asset Requirements

-   **3D Models (USDZ format preferred):**
    -   Player Character (e.g., Chicken) - Low-poly/voxel style.
    -   Vehicles (various types/colors) - Low-poly/voxel style.
    -   Logs - Low-poly/voxel style.
    -   Trees/Static Obstacles - Low-poly/voxel style.
    -   Lane Segments (Grass, Road, Water textures/models).
    -   *License:* All assets must have licenses permissive for use in the application. Sources like Sketchfab, Free3D, or custom creation.
-   **Audio Files (Optional):** Sound effects and background music (e.g., `.wav`, `.mp3`, `.aac`).

## 8. Implementation Plan / Modules

1.  **Project Setup:** Initialize Xcode visionOS project with RealityKit/ARKit capabilities.
2.  **Plane Detection & Anchoring:**
    -   Configure `ARKitSession` for horizontal plane detection (`.table`).
    -   Create a root `AnchorEntity` attached to the first suitable detected plane.
    -   Place a temporary visual indicator (e.g., a cube) on the anchor to confirm placement.
3.  **Asset Loading & Basic Scene:**
    -   Source or create initial placeholder 3D models (character, one lane type, one obstacle type) in USDZ format.
    -   Load the character model and place it as a `ModelEntity` relative to the root anchor.
    -   Load and place a few static lane segments.
4.  **Character Control (Look + Tap):**
    -   Implement the gaze detection and tap gesture recognition.
    -   Create `PlayerMovementComponent`.
    -   Translate input into grid-based movement updates for the character's `Transform`.
    -   Add basic hop animation (e.g., simple up-and-down motion).
5.  **Procedural Lane Generation:**
    -   Create `ModelEntity` representations for each lane type (Road, Grass, Water).
    -   Implement logic to dynamically add new lanes ahead of the player's current position.
    -   Implement logic to remove lanes that are far behind the player.
6.  **Obstacle Spawning & Movement:**
    -   Create `ModelEntity` for initial obstacles (e.g., a Car).
    -   Implement `CarMovementComponent` (or similar) with constant velocity across the lane.
    -   Create spawning logic to introduce cars from off-screen edges on Road lanes.
    -   Implement despawning logic for obstacles leaving the play area.
    -   Repeat for Logs on Water lanes.
7.  **Collision Detection & Game Logic:**
    -   Add `CollisionComponent` to the player, obstacles, and potentially specific lane types (Water). Define appropriate collision groups and masks.
    -   Subscribe to collision events.
    -   Implement game over logic upon player-car collision or player-water collision (without landing on a log).
    -   Implement safe landing detection (grass, logs).
8.  **Scoring & UI:**
    -   Implement score tracking based on forward progress.
    -   Use SwiftUI `RealityView` attachments or overlay views to display the current score.
    -   Implement Game Over screen/state displaying final score and restart option.
    -   Implement Start Menu/Instructions state.
9.  **Refinement:**
    -   Add sound effects and background music.
    -   Improve animations and visual effects (e.g., splash effect).
    -   Add more variety in obstacles and lane patterns.
    -   Optimize performance, focusing on entity count and procedural generation efficiency.
    -   Refine input responsiveness and feel.

## 9. Current Status (Assumed)

-   Basic Xcode project structure for a visionOS app exists.
-   Core game logic, asset integration, AR interactions, and specific features outlined above need implementation.

## 10. Future Enhancements (Optional)

-   Different playable characters with unique abilities/visuals.
-   Coin collection and unlockables.
-   Power-ups.
-   More complex obstacles (e.g., trains).
-   Online leaderboards.
-   More sophisticated environmental effects.
-   Alternative control schemes (e.g., hand gestures via `HandTrackingProvider`). 