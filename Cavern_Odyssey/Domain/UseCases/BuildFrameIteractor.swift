import Foundation

struct BuiltFrame {
    let frame: GameFrameDTO
    let visible: Set<Coordinates>
    let explored: Set<Coordinates>
}

protocol BuildFrameUseCase {
    func buildFrame(fovRadius: Int) -> BuiltFrame
}

import Foundation

final class BuildFrameInteractor: BuildFrameUseCase {
    private let gameStateUC: CurrentGameStateUseCase
    private let visibilityUC: VisibilityUseCase

    init(gameStateUC: CurrentGameStateUseCase, visibilityUC: VisibilityUseCase) {
        self.gameStateUC = gameStateUC
        self.visibilityUC = visibilityUC
    }

    func buildFrame(fovRadius: Int) -> BuiltFrame {
        guard case let .success(domainSnap) = gameStateUC.execute() else {
            fatalError("GameStateUC.execute() failed")
        }

        let frame = DomainToDTOMapper.map(domainSnap)
        let vis = visibilityUC.refreshVisibility(using: frame, fovRadius: fovRadius)

        return BuiltFrame(frame: frame, visible: vis.visible, explored: vis.explored)
    }
}
