import Foundation

// Система для обработки движения врагов
enum EnemyMovementSystem {
    
    // Обрабатывает ход всех врагов на уровне
    static func processEnemyTurns(in state: inout LevelState, playerPos: Coordinates) {
        for i in state.enemies.indices {
            var enemy = state.enemies[i]
            
            // Обновляем статус-эффекты для всех врагов
//            enemy.model.updateStatusEffect()
            
            // Пропускаем врагов с статус-эффектами (rest, sleep)
            guard enemy.model.canAct else {
                state.enemies[i] = enemy
                continue
            }
            
            // Получаем следующую позицию для движения
            if let nextPos = getNextPosition(for: enemy, playerPos: playerPos, in: state) {
                enemy.model.lastPosition = enemy.position
                enemy.position = nextPos
                state.enemies[i] = enemy
            }
            processSpecialAbilities(for: &state.enemies[i])
        }
    }
    
    // Определяет следующую позицию для врага
    private static func getNextPosition(for enemy: PlacedEnemy, playerPos: Coordinates, in state: LevelState) -> Coordinates? {
        let distanceToPlayer = abs(enemy.position.x - playerPos.x) + abs(enemy.position.y - playerPos.y)
        
        // Проверяем, должен ли враг преследовать игрока
        if distanceToPlayer <= enemy.model.hostility.aggroRadius {
            
            // Если игрок в соседней клетке - атакуем (не двигаемся)
            if distanceToPlayer == 1 {
                return nil // Не двигаемся, но запустим битву через столкновение
            }
            
            // Пытаемся найти путь к игроку
            if let chaseMove = ChaseMovement().getNextMove(current: enemy.position, playerPos: playerPos, in: state) {
                return chaseMove
            }
        }
        
        // Если преследование невозможно или не нужно, используем свой паттерн
        switch enemy.model.type {
        case .zombie, .vampire:
            return RandomMovement().getNextMove(current: enemy.position, playerPos: playerPos, in: state)
            
        case .ghost:
            // Привидение всегда ходит случайно
            return RandomMovement().getNextMove(current: enemy.position, playerPos: playerPos, in: state)
            
        case .ogre:
            // Огр ходит на 2 клетки
            return getDoubleMove(for: enemy, in: state)
            
        case .snakeMage:
            return DiagonalMovement().getNextMove(current: enemy.position, playerPos: playerPos, in: state)
            
        case .mimic:
            return nil
        }
    }
    
    // Двойной ход для огра
    private static func getDoubleMove(for enemy: PlacedEnemy, in state: LevelState) -> Coordinates? {
        let directions = [
            Coordinates(x: 0, y: -2),  // up
            Coordinates(x: 0, y: 2),   // down
            Coordinates(x: -2, y: 0),  // left
            Coordinates(x: 2, y: 0)    // right
        ]
        
        let possibleMoves = directions.compactMap { move -> Coordinates? in
            let newPos = Coordinates(x: enemy.position.x + move.x, y: enemy.position.y + move.y)
            return isPositionWalkable(newPos, in: state) ? newPos : nil
        }
        
        return possibleMoves.randomElement()
    }
    
    private static func processSpecialAbilities(for enemy: inout PlacedEnemy) {
            switch enemy.model.type {
            case .ghost:
                // Привидение становится невидимым с шансом 30%
                if Int.random(in: 1...100) <= 30 {
                    let isAlreadyInvisible = enemy.model.statusEffects.contains { effect in
                        if case .invisible = effect { return true }
                        return false
                    }
                    
                    if !isAlreadyInvisible {
                        enemy.model.applyStatus(.invisible(duration: 1))
                    }
                }
                
            default:
                break
            }
        }
    
    // Вспомогательные функции
    private static func findRoomContaining(_ pos: Coordinates, in state: LevelState) -> Room? {
        return state.geometry.rooms.first { room in
            pos.x >= room.left && pos.x <= room.right &&
            pos.y >= room.top && pos.y <= room.bottom
        }
    }
    
    // Получает позиции в радиусе от текущей позиции
    private static func getPositionsInRadius(from center: Coordinates, radius: Int, in room: Room, state: LevelState) -> [Coordinates] {
        var positions: [Coordinates] = []
        
        // Перебираем все клетки в радиусе
        for y in max(room.top, center.y - radius)...min(room.bottom, center.y + radius) {
            for x in max(room.left, center.x - radius)...min(room.right, center.x + radius) {
                let pos = Coordinates(x: x, y: y)
                
                // Проверяем расстояние (не более 3 клеток)
                let distance = abs(x - center.x) + abs(y - center.y)
                if distance <= radius &&
                   distance > 0 && // Исключаем текущую позицию
                   isPositionWalkable(pos, in: state) {
                    positions.append(pos)
                }
            }
        }
        
        return positions
    }
    
    private static func getWalkablePositions(in room: Room, excluding exclude: Coordinates, in state: LevelState) -> [Coordinates] {
        var positions: [Coordinates] = []
        
        for y in room.top...room.bottom {
            for x in room.left...room.right {
                let pos = Coordinates(x: x, y: y)
                if pos != exclude && isPositionWalkable(pos, in: state) {
                    positions.append(pos)
                }
            }
        }
        
        return positions
    }
}
