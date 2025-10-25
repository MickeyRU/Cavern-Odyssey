import Foundation

struct VisibilitySnapshot {
    let visible: Set<Coordinates>   // видно сейчас
    let explored: Set<Coordinates>  // накопленный след
}

protocol VisibilityUseCase {
    /// На основании готового кадра (DTO) считает FOV и обновляет 'explored' в домене.
    func refreshVisibility(using frame: GameFrameDTO, fovRadius: Int) -> VisibilitySnapshot
}

final class VisibilityInteractor: VisibilityUseCase {
    private let store: LevelStateStore

    init(store: LevelStateStore) {
        self.store = store
    }

    func refreshVisibility(using frame: GameFrameDTO, fovRadius: Int) -> VisibilitySnapshot {
        let playerPos = frame.actors.player.position
        let cur = FOV.compute(from: playerPos, world: frame.world, radius: fovRadius)

        var st = store.state
        st.explored.formUnion(cur.visible)
        store.state = st

        return VisibilitySnapshot(visible: cur.visible, explored: st.explored)
    }
}
