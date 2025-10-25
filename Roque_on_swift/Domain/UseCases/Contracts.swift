import Foundation

// Команды игрока
enum PlayerAction {
    case moveUp, moveDown, moveLeft, moveRight
    case equipWeapon(Int?)     // nil → убрать оружие
    case eatFood(Int)          // индекс в массиве foods
    case drinkPotion(Int)      // индекс в массиве potions
    case readScroll(Int)       // индекс в массиве scrolls
}

// Ошибки
enum GameError: Error {
    case stateNotReady
    case invalidMove
}

// Снимок текущего состояния для Presentation
protocol CurrentGameStateUseCase {
    func execute() -> Result<DomainSnapshot, GameError>
}

// Применение команды игрока
protocol PlayerActionUseCase {
    func execute(_ action: PlayerAction) -> PlayerActionOutcome
}

// Простое хранилище доменного состояния уровня
protocol LevelStateStore: AnyObject {
    var state: LevelState { get set}
    var gameSession: GameSession { get set}
    
    func startGame()                // с текущим уровнем (перегенерация)
    func nextLevel()                 // увеличить уровень и сгенерировать
}

// Выполнить один "тик" статусов (персонажа/врагов) в текущем состоянии.
protocol TickStatusesUseCase {
    func execute()
}

// Логика всех действий врагов за один "тик".
protocol EnemyTurnUseCase {
    func execute()
}
