import Foundation

final class InMemoryLevelStateStore: LevelStateStore {
    var gameSession: GameSession
    var state: LevelState
    
    private let generator: LevelGenerator
    private let baseCanvas: Size
    
    init(generator: LevelGenerator, session: GameSession, canvas: Size)
    {
        self.generator = generator
        self.baseCanvas = canvas
        self.gameSession = session
        self.state = generator.generate(canvas: baseCanvas, session: &self.gameSession)
    }
    init(
        generator: LevelGenerator,
        session: GameSession,
        canvas: Size,
        initialState: LevelState,
        worldVersion: Int
    ) {
        self.generator = generator
        self.baseCanvas = canvas
        self.gameSession = session
        self.state = initialState
    }
    func startGame() {
        state = generator.generate(canvas: baseCanvas, session: &gameSession)
    }
    
    /// Следующий уровень (depth инкрементим)
    func nextLevel() {
        // переносим прогресс героя между уровнями
        gameSession.player = state.player.model
        gameSession.depth += 1

        state = generator.generate(canvas: baseCanvas, session: &gameSession)
    }
}
