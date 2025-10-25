import Foundation

final class LevelStateStoreFactory {
    static func make(snapshot: DomainSnapshot, session: GameSession,
                     generator: LevelGenerator, canvas: Size, worldVersion: Int = 1) -> LevelStateStore {
        let initialState = LevelState( geometry: GeometrySnapshot( canvasSize: snapshot.canvasSize,
                rooms: snapshot.rooms,
                corridors: snapshot.corridors
            ),
            player: snapshot.player,
            enemies: snapshot.enemies,
            hud: snapshot.hud,
            worldItems: snapshot.worldItems,
            explored: snapshot.explored
        )
        
        let store = InMemoryLevelStateStore(
            generator: generator,
            session: session,
            canvas: canvas,
        )
        store.state = initialState
        return store
    }
    
    static func parseFirstScreenInput(choice: Int, generator: LevelGenerator,
                                      canvas: Size, paths: SavePaths ) -> LevelStateStore {
        switch choice {
        case 1:
            // Новая игра
            let playerName = Menu.AskPlayerNameScreen(canvasSize: canvas)
            let session = GameSession(player: Character(name:playerName), depth: 1)
            RunRecord.addRecord.playerName = playerName
            return InMemoryLevelStateStore(generator: generator, session: session, canvas: canvas)
            
        case 2:
            // Загрузка сохранённой игры
            let snapshotRepo = FileSnapshotRepository(file: paths.lastSession)
            let sessionRepo = FileGameSessionRepository(file: paths.lastGameSession)
            guard case let .success(snapshot) = snapshotRepo.load(),
                  case let .success(session) = sessionRepo.load() else {
                Menu.messageError("Нет сохраненной игры")
                exit(0)
            }
            RunRecord.addRecord.playerName = snapshot.player.model.name
            return LevelStateStoreFactory.make(
                snapshot: snapshot,
                session: session,
                generator: generator,
                canvas: canvas)
        default:
            // Таблица лидеров
            let leaderboardRepo = FileMainRepository(file: paths.leaderboard)
            Menu.LeaderboardScreen(canvasSize: canvas, repository: leaderboardRepo)
            exit(0)
        }
    }
}
