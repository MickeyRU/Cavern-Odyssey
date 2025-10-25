import Foundation

/// Что делать контроллеру после "тика" бизнес-логики.
enum TurnDirective {
    case continueGame     // продолжаем обычный цикл
    case levelCompleted   // перешли на следующий уровень
    case gameCompleted    // победа (финал игры)
    case gameOver         // смерть героя
}

/// Единый use-case "шага игры":
/// принимает результат действия игрока и выполняет:
/// - (возможный) бой, если игрок инициировал engage
/// - ход врагов (если не пропущен) + (возможный) бой от врагов
/// - переход уровня, завершение игры
protocol GameStepUseCase {
    func advance(after playerOutcome: PlayerActionOutcome) -> TurnDirective
}

/// Оркестратор одного "тика" игры.
/// Внутри:
/// - реакция на исход хода игрока (engage/reachedExit/…)
/// - движение врагов
/// - проверка столкновений и запуск боя
/// - обновление LevelStateStore
final class GameStepInteractor: GameStepUseCase {
    private let gameStateUC: CurrentGameStateUseCase
    private let finishUC: FinishLevelUseCase
    private let battleService: BattleService
    private let store: LevelStateStore
    
    /// Флаг: пропустить следующий ход врагов (например, после боя).
    private var skipEnemyTurn = false
    
    init(gameStateUC: CurrentGameStateUseCase,
         finishUC: FinishLevelUseCase,
         battleService: BattleService,
         store: LevelStateStore) {
        self.gameStateUC = gameStateUC
        self.finishUC = finishUC
        self.battleService = battleService
        self.store = store
    }
    
    /// Главная точка: один "тик" после хода игрока.
    func advance(after playerOutcome: PlayerActionOutcome) -> TurnDirective {
        // 1) реакция на исход хода игрока
        switch playerOutcome {
        case .engage(let enemyId, _):
            if let dir = engage(by: enemyId) { return dir }
            // после боя пропускаем ход врагов
            skipEnemyTurn = true
            
        case .reachedExit:
            switch finishUC.execute() {
            case .success(.gameCompleted): return .gameCompleted
            case .success(.nextLevel):     return .levelCompleted
            case .failure(let e):
                ChatLogger.shared.addMessage("Ошибка завершения уровня: \(e)")
            }
            
        case .moved, .blockedTerrain:
            break
        }
        
        // 2) ход врагов (если не пропускаем)
        if !skipEnemyTurn {
            guard case let .success(snap) = gameStateUC.execute() else {
                ChatLogger.shared.addMessage("❌ Ошибка состояния игры")
                return .continueGame
            }
            
            var state = store.state
            let playerPos = snap.player.position
            
            // перемещение всех врагов
            EnemyMovementSystem.processEnemyTurns(in: &state, playerPos: playerPos)
            store.state = state
            
            // 3) проверка соприкосновения → бой
            if let adjacent = adjacentEnemy(to: playerPos, in: state) {
                if let dir = engage(by: adjacent.id) { return dir }
                // бой был — пропускаем следующий ход врагов
                skipEnemyTurn = true
            }
        } else {
            // истратили пропуск
            skipEnemyTurn = false
        }
        
        // 4) тик эффектов — только если игра не завершилась/не сменился уровень
        tickStatuses()
        
        return .continueGame
    }
    
    // MARK: - Tick
    private func tickStatuses() {
        var state = store.state
        state.player.model.updateStatusEffect()
        store.state = state
    }
    
    // MARK: - Вспомогательные
    
    /// Находит врага, стоящего вплотную к игроку (манхэттенское расстояние 1).
    /// Мимик, если замаскирован, игнорируется.
    private func adjacentEnemy(to playerPos: Coordinates, in state: LevelState) -> PlacedEnemy? {
        state.enemies.first { e in
            let m = e.model
            if m.type == .mimic && m.isDisguised { return false }
            let dx = abs(e.position.x - playerPos.x)
            let dy = abs(e.position.y - playerPos.y)
            return (dx + dy) == 1
        }
    }
    
    /// Запускает бой по `enemyId`, обновляет доменное состояние и
    /// возвращает директиву, если игра закончилась. Иначе — `nil`.
    private func engage(by enemyId: ActorID) -> TurnDirective? {
        guard case let .success(snap) = gameStateUC.execute() else {
            ChatLogger.shared.addMessage("❌ Ошибка состояния игры")
            return nil
        }
        
        var state = store.state
        guard let idx = state.enemies.firstIndex(where: { $0.id == enemyId }) else {
            ChatLogger.shared.addMessage("⚠️ Враг не найден (id=\(enemyId))")
            return nil
        }
        
        let enemy = state.enemies[idx].model
        let hero  = snap.player.model
        
        // Чистая боевая математика — в сервисе
        let result = battleService.startBattle(hero: hero, enemy: enemy)
        
        // Обновляем домен: герой и враг(и)
        state.player.model = result.updatedHero
        if result.updatedEnemy.currentHealth <= 0 {
            state.enemies.remove(at: idx)
        } else {
            state.enemies[idx].model = result.updatedEnemy
        }
        store.state = state
        
        // Финальные исходы
        switch result.result {
        case .heroDied:
            return .gameOver
        case .heroWon, .enemyFled:
            return nil
        }
    }
}
