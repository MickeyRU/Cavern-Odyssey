import Foundation

final class CurrentGameStateInteractor: CurrentGameStateUseCase {
    private let store: LevelStateStore
    init(store: LevelStateStore) { self.store = store }
    
    func execute() -> Result<DomainSnapshot, GameError> {
        let s = store.state
        let snap = DomainSnapshot(
            canvasSize: s.geometry.canvasSize,
            rooms: s.geometry.rooms,
            corridors: s.geometry.corridors,
            worldItems: s.worldItems,
            player: s.player,
            enemies: s.enemies,
            hud: s.hud,
            explored: s.explored
        )
        return .success(snap)
    }
}
