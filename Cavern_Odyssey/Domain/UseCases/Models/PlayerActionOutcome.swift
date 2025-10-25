import Foundation

enum PlayerActionOutcome {
    case moved
    case blockedTerrain
    case engage(ActorID, Enemy)
    case reachedExit
}
