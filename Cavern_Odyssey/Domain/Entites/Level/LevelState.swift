import Foundation

struct LevelState {
    var geometry: GeometrySnapshot
    var player: PlacedPlayer
    var enemies: [PlacedEnemy]
    var hud: DomainHUD
    var worldItems: [PlacedItem]
    
    /// Клетки уровня, которые уже были видны игроку.
    var explored: Set<Coordinates> = []
}
