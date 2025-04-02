// The main RealityView for the game 

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit // Import ARKit for session and plane detection
// import Combine // No longer needed here

// Helper class to manage ARKit session
@MainActor
class ARKitSessionManager: ObservableObject {
    let session = ARKitSession()
    let worldTracking = WorldTrackingProvider()

    func runSession() async {
        // Check permissions if necessary, omitted for brevity
        // Ensure world tracking is supported
        guard WorldTrackingProvider.isSupported else {
            print("ARKitSessionManager: WorldTrackingProvider is not supported on this device.")
            // Handle error appropriately - perhaps show an alert
            return
        }

        print("ARKitSessionManager: WorldTrackingProvider is supported. Running session.")
        do {
            try await session.run([worldTracking])
            print("ARKitSessionManager: Session started successfully.")
        } catch {
            print("ARKitSessionManager: Error running ARKit session: \\(error)")
            // Handle error appropriately
        }
    }

     // Function to get the current device transform
     func getDeviceTransform() -> simd_float4x4? {
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
            print("ARKitSessionManager: Failed to query device anchor.")
            return nil
        }
        return deviceAnchor.originFromAnchorTransform
    }
}

struct ImmersiveView: View {
    @StateObject var gameManager = GameManager()
    @StateObject var arkitSessionManager = ARKitSessionManager()
    @State var rootEntity = Entity()

    var body: some View {
        // Explicitly capture gameManager for use in closures
        let capturedGameManager = gameManager

        RealityView { content in
            print("ImmersiveView: RealityView make - Adding root entity.")
            content.add(rootEntity)
        }
        .task {
            print("ImmersiveView: Task starting ARKit session.")
            await arkitSessionManager.runSession()
            // Do NOT call setup here anymore
        }
        .onAppear {
            print("ImmersiveView: onAppear - Calling GameManager setup.")
            // Call setup using the captured reference
            capturedGameManager.setup(rootEntity: rootEntity, worldTracking: arkitSessionManager.worldTracking)
        }
        .onDisappear {
            print("ImmersiveView: onDisappear.")
            // Call a cleanup method on gameManager using the captured reference
            capturedGameManager.handleDisappear()
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { value in
             print("ImmersiveView: Spatial Tap detected.")
             // Use the captured reference
             capturedGameManager.handleTap(on: value.entity)
         })
    }
}

// Corrected Preview - ImmersiveView manages its own GameManager
#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}