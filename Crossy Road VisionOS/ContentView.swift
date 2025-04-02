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

            Button {
                Task {
                    switch gameManager.currentGameState {
                    case .playing:
                        // Stop the game
                        print("ContentView: Stopping game...")
                        await dismissImmersiveSpace()
                        gameManager.resetGame()
                    case .ready:
                        // ImmersiveView is ready, start the actual game logic
                        print("ContentView: Starting game logic...")
                        await gameManager.startGame()
                    case .setup, .gameOver:
                        // Request to open the immersive space.
                        // setupGame will be called by ImmersiveView's make, setting state to .ready.
                        print("ContentView: Requesting immersive space...")
                        let result = await openImmersiveSpace(id: "ImmersiveGameSpace")
                        if case .error = result {
                            print("ContentView: Error opening immersive space.")
                        } else if case .opened = result {
                            print("ContentView: Immersive space opened request successful (View will now appear and set state to ready)." )
                            // Don't call startGame here - wait for next button press when state is .ready
                        }
                    case .placing:
                        // Optional: Handle the placing state if needed, maybe do nothing or disable button
                        print("ContentView: Game is currently in the placing state.")
                    }
                }
            } label: {
                // Determine button label based on state
                switch gameManager.currentGameState {
                case .playing:
                    Text("Stop Game")
                case .ready:
                    Text("Start Game (Ready)") // Indicate it's ready for game logic
                case .setup, .gameOver:
                    Text("Start Game") // This press will open the space
                case .placing:
                    Text("Placing...") // Indicate the placing state
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