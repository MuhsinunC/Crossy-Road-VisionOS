import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    // Use @StateObject since ContentView owns this instance
    @StateObject var gameManager = GameManager()

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    // Define the correct ID matching the App definition
    private let immersiveSpaceID = "ImmersiveGameSpace"

    var body: some View {
        VStack {
            Text("Crossy Road Vision")
                .font(.largeTitle)
            
            // Use the correct property name: gameState
            if gameManager.gameState == .menu || gameManager.gameState == .gameOver {
                Button("Start Game") {
                    Task {
                        switch gameManager.gameState {
                            case .menu, .gameOver:
                                if !immersiveSpaceIsShown {
                                    print("ContentView: Opening Immersive Space with ID: \(immersiveSpaceID)")
                                    // Use the correct ID
                                    let result = await openImmersiveSpace(id: immersiveSpaceID)
                                    if case .error = result {
                                        print("ContentView Error: Failed to open immersive space. Is \(immersiveSpaceID) defined in the App struct?")
                                        // Handle error appropriately
                                    } else if case .userCancelled = result {
                                         print("ContentView: User cancelled immersive space opening.")
                                         // Handle cancellation
                                    } else {
                                         showImmersiveSpace = true
                                         immersiveSpaceIsShown = true
                                         print("ContentView: Immersive Space open, starting game.")
                                         // Give RealityView time to appear before starting
                                         try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
                                         gameManager.startGame()
                                    }
                                } else {
                                    print("ContentView: Immersive space already shown, resetting/starting game.")
                                    gameManager.resetGame() // Ensure clean state
                                    gameManager.startGame()
                                }
                            case .playing:
                                // Should not happen if button text is correct, but handle defensively
                                print("ContentView: Game already playing, button shouldn't be 'Start Game'")
                                break // Do nothing
                        }
                    }
                }
                .padding()

                // Show score if game over
                if gameManager.gameState == .gameOver {
                     Text("Game Over! Score: \(gameManager.score)")
                         .font(.title2)
                         .padding(.top)
                 }
                
            } else if gameManager.gameState == .playing {
                Button("End Game") {
                    print("ContentView: End Game button tapped.")
                    gameManager.resetGame() // Reset state immediately
                    // Optionally dismiss immersive space, or leave it open for restart
                     Task {
                         print("ContentView: Dismissing Immersive Space...")
                         await dismissImmersiveSpace()
                         showImmersiveSpace = false
                         immersiveSpaceIsShown = false
                     }
                }
                .padding()
                
                Text("Score: \(gameManager.score)")
                   .font(.title2)
            }
            
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    // This check might be redundant now with the button logic, 
                    // but kept for potential other ways showImmersiveSpace might change
                    if !immersiveSpaceIsShown {
                        print("ContentView onChange: Opening Immersive Space via flag with ID: \(immersiveSpaceID)...")
                         // Use the correct ID
                        let result = await openImmersiveSpace(id: immersiveSpaceID)
                        if case .error = result {
                            print("ContentView onChange Error: Failed to open immersive space.")
                            showImmersiveSpace = false // Revert state on failure
                        } else if case .userCancelled = result {
                            print("ContentView onChange: User cancelled opening.")
                            showImmersiveSpace = false
                        } else {
                            immersiveSpaceIsShown = true
                            // Start game is now handled by the button action
                        }
                    }
                } else if immersiveSpaceIsShown {
                     print("ContentView onChange: Dismissing Immersive Space via flag...")
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                    gameManager.resetGame() // Reset game when space is dismissed
                }
            }
        }
        // Pass gameManager as an environment object if needed by ImmersiveView, 
        // but ImmersiveView now manages its own @StateObject
        // .environmentObject(gameManager) 
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
} 