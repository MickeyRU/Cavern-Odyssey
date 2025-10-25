import Foundation

enum EnemyType {
    case zombie
    case vampire
    case ghost
    case ogre
    case snakeMage
    case mimic
}

enum Hostility {
    case noagro
    case hostile
    case aggressive
    case passive
    
    var aggroRadius: Int {
        switch self {
        case .noagro: return 0
        case .passive: return 1
        case .hostile: return 3
        case .aggressive: return 5
        }
    }
}

enum SpecialEffect {
    case lifeDrain
    case invisibility
    case rest
    case sleep
    
    var effect: Effect {
        switch self {
        case .lifeDrain: return LifeDrainEffect()
        case .invisibility: return InvisibilityEffect()
        case .rest: return RestEffect()
        case .sleep: return SleepEffect()
        }
    }
}

struct Enemy: StatusApplicable {
    let type: EnemyType
    var avatar: String
    var name: String
    var maxHealth: Int
    var currentHealth: Int
    var dexterity: Int
    var strength: Int
    var gold: Int
    var hostility: Hostility
    var effects: [Effect]
    var statusEffects: [StatusEffect] = []
    var lastPosition: Coordinates?
    var evasionUsed: Bool = false
    var isInvisible: Bool {
        return statusEffects.contains { effect in
            if case .invisible = effect { return true }
            return false
        }
    }
    var isDisguised: Bool = true
    
}

// Протокол для паттернов движения
protocol MovementPattern {
    func getNextMove(current: Coordinates, playerPos: Coordinates, in state: LevelState) -> Coordinates?
}

// MARK: - Паттерны движения

// Движение в случайном направлении на 1 клетку (Зомби, Вампир)
struct RandomMovement: MovementPattern {
    
    // Определяем следующую позицию в случайном направлении
    func getNextMove(current: Coordinates, playerPos: Coordinates, in state: LevelState) -> Coordinates? {
        // Все возможные направления
        let directions = [
            Coordinates(x: 0, y: -1),  // вверх
            Coordinates(x: 0, y: 1),   // вниз
            Coordinates(x: -1, y: 0),  // влево
            Coordinates(x: 1, y: 0)    // вправо
        ]
        
        // Фильтруем только проходимые направления
        let possibleMoves = directions.compactMap { move -> Coordinates? in
            let newPos = Coordinates(x: current.x + move.x, y: current.y + move.y)
            return isPositionWalkable(newPos, in: state) ? newPos : nil
        }
        
        // Возвращаем случайное направление или nil
        return possibleMoves.randomElement()
    }
}

// Движение в случайном направлении на 2 клетки (Огр)
struct DoubleMove: MovementPattern {
    
    // Определяет позицию на 2 клетки в случайном направлении
    func getNextMove(current: Coordinates, playerPos: Coordinates, in state: LevelState) -> Coordinates? {
        // Возможные направления на 2 клетки:
        let directions = [
            Coordinates(x: 0, y: -2),  // вверх (2 клетки)
            Coordinates(x: 0, y: 2),   // вниз (2 клетки)
            Coordinates(x: -2, y: 0),  // влево(2 клетки)
            Coordinates(x: 2, y: 0)    // вправо (2 клетки)
        ]
        
        // Фильтруем только проходимые направления:
        let possibleMoves = directions.compactMap { move -> Coordinates? in
            let newPos = Coordinates(x: current.x + move.x, y: current.y + move.y)
            return isPositionWalkable(newPos, in: state) ? newPos : nil
        }
        
        // Возвращаем случайное направление или nil
        return possibleMoves.randomElement()
    }
}

// Движение по диагонали (Змей-Маг)
struct DiagonalMovement: MovementPattern {
    func getNextMove(current: Coordinates, playerPos: Coordinates, in state: LevelState) -> Coordinates? {
        // Все возможные направления
        let diagonals = [
            Coordinates(x: 1, y: 1),    // вниз-вправо
            Coordinates(x: -1, y: 1),   // вниз-влево
            Coordinates(x: 1, y: -1),   // вверх-вправо
            Coordinates(x: -1, y: -1)   // вверх-влево
        ]
        
        // Фильтруем только проходимые направления
        let possibleMoves = diagonals.compactMap { move -> Coordinates? in
            let newPos = Coordinates(x: current.x + move.x, y: current.y + move.y)
            return isPositionWalkable(newPos, in: state) ? newPos : nil
        }
        
        // Возвращаем случайное направление или nil
        return possibleMoves.randomElement()
    }
}

// Преследование игрока
struct ChaseMovement: MovementPattern {
    
    // Определяем направление движения к игроку
    func getNextMove(current: Coordinates, playerPos: Coordinates, in state: LevelState) -> Coordinates? {
        // Вычисляем разницу по X и Y между врагом и игроком
        let dx = playerPos.x - current.x
        let dy = playerPos.y - current.y
        
        var possibleMoves: [Coordinates] = []
        
        // Приоритет: движение по основной оси (где разница больше)
        if abs(dx) > abs(dy) {
            // Двигаемся по X
            let moveX = dx > 0 ? 1 : -1
            possibleMoves.append(Coordinates(x: current.x + moveX, y: current.y))
            
            // Добавляем движение по Y как альтернативу
            if dy != 0 {
                let moveY = dy > 0 ? 1 : -1
                possibleMoves.append(Coordinates(x: current.x, y: current.y + moveY))
            }
        } else {
            // Двигаемся по Y
            let moveY = dy > 0 ? 1 : -1
            possibleMoves.append(Coordinates(x: current.x, y: current.y + moveY))
            // Добавляем движение по X как альтернативу
            if dx != 0 {
                let moveX = dx > 0 ? 1 : -1
                possibleMoves.append(Coordinates(x: current.x + moveX, y: current.y))
            }
        }
        
        // Выбираем первую доступную клетку
        for move in possibleMoves {
            if isPositionWalkable(move, in: state) {
                return move
            }
        }
        
        // Нет доступных путей к игроку
        return nil
    }
}

// Проверка может ли переместится на позицию
func isPositionWalkable(_ pos: Coordinates, in state: LevelState) -> Bool {
    // Проверяем, что позиция в пределах карты
    guard pos.x >= 0, pos.y >= 0,
          pos.x < state.geometry.canvasSize.width,
          pos.y < state.geometry.canvasSize.height else {
        return false
    }
    
    // Проверяем, что нет другого врага на этой позиции
    if state.enemies.contains(where: { $0.position == pos }) {
        return false
    }
    
    if state.player.position == pos {
           return false
       }
    
    // Проверяем террейн (стены, пол, коридоры)
    let movementService = MovementService()
    return movementService.isWalkableTerrain(pos, in: state)
}

extension Enemy {
    static let zombie = Enemy(
        type: .zombie,
        avatar: "🧟‍♂️",
        name: "Зомби",
        maxHealth: 15,
        currentHealth: 15,
        dexterity: 4,
        strength: 6,
        gold: 10,
        hostility: .hostile,
        effects: []
    )
    static let vampire = Enemy(
        type: .vampire,
        avatar: "🧛🏻",
        name: "Вампир",
        maxHealth: 20,
        currentHealth: 20,
        dexterity: 9,
        strength: 8,
        gold: 20,
        hostility: .aggressive,
        effects: [LifeDrainEffect()]
    )
    static let ghost = Enemy(
        type: .ghost,
        avatar: "👻",
        name: "Привидение",
        maxHealth: 12,
        currentHealth: 12,
        dexterity: 8,
        strength: 4,
        gold: 15,
        hostility: .passive,
        effects: [InvisibilityEffect()]
    )
    static let ogre = Enemy(
        type: .ogre,
        avatar: "🧌",
        name: "Огр",
        maxHealth: 40,
        currentHealth: 40,
        dexterity: 6,
        strength: 12,
        gold: 50,
        hostility: .hostile,
        effects: [RestEffect()]
    )
    static let snakeMage = Enemy(
        type: .snakeMage,
        avatar: "🐍",
        name: "Змей-Маг",
        maxHealth: 16,
        currentHealth: 16,
        dexterity: 12,
        strength: 5,
        gold: 40,
        hostility: .hostile,
        effects: [SleepEffect()]
    )
    static let mimic = Enemy(
        type: .mimic,
        avatar: "🦎",
        name: "Мимик",
        maxHealth: 30,
        currentHealth: 30,
        dexterity: 10,
        strength: 1,
        gold: 40,
        hostility: .noagro,
        effects: [],
        isDisguised: true
    )
    
    
}
