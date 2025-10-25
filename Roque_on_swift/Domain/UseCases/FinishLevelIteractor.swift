import Foundation

protocol FinishLevelUseCase {
    func execute() -> Result<FinishLevelOutcome, GameError>
}

enum FinishLevelOutcome {
    case nextLevel
    case gameCompleted
}

final class FinishLevelInteractor: FinishLevelUseCase {
    private let store: LevelStateStore
    private let maxDepth = 21

    init(store: LevelStateStore) {
        self.store = store
    }

    func execute() -> Result<FinishLevelOutcome, GameError> {
        // Если игрок уже достиг 21 уровня — считаем игру пройденной
        if store.gameSession.depth >= maxDepth {
            return .success(.gameCompleted)
        }

        // Иначе просто переход на следующий уровень
        store.nextLevel()
        return .success(.nextLevel)
    }
}
