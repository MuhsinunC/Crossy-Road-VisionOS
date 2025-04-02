import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @ObservedObject var gameManager: GameManager // Get the manager

    var body: some View {
        VStack {
            Text("Crossy Road Vision")
                .font(.largeTitle)
                .padding()

            Button(gameManager.currentGameState == .playing ? "Stop Game" : "Start Game") {
                Task {
                    if gameManager.currentGameState == .playing {
                        await dismissImmersiveSpace()
                        gameManager.resetGame() // Reset state when stopping
                    } else {
                        let result = await openImmersiveSpace(id: "ImmersiveGameSpace")
                        if case .error = result {
                            print("Error opening immersive space.")
                            // Handle error appropriately
                        }
                        // Game state will likely be set to .playing within ImmersiveView setup
                    }
                }
            }
            .padding()

            // Display score or other info from gameManager if needed here
            Text("Score: \(gameManager.score)")
                .font(.title)
        }
        .padding()
    }
} 