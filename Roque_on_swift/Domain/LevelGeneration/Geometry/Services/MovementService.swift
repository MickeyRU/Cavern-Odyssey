import Foundation

// Проверка только «террейна»: стены/пол/двери/коридоры, без учёта акторов.
struct MovementService {
    func isWalkableTerrain(_ p: Coordinates, in s: LevelState) -> Bool {
        guard p.x >= 0, p.y >= 0, p.x < s.geometry.canvasSize.width, p.y < s.geometry.canvasSize.height else {
            ChatLogger.shared.addMessage("Выход за границы")
            return false }

        // Комнаты: внутренняя область + двери
        for r in s.geometry.rooms {
            if let door = r.doors.first(where: { $0.position == p }) {
                switch door.kind {
                case .open: return true
                case .locked(let color):
                    return s.player.model.inventory.containsKey(color)
                }
            }
            
            // пол комнаты
            if r.width >= 3, r.height >= 3,
               (r.left+1...r.right-1).contains(p.x),
               (r.top+1...r.bottom-1).contains(p.y) { return true }
        }

        // Коридоры
        for c in s.geometry.corridors where c.tiles.contains(p) { return true }

        return false
    }

    // Возвращаем не только размещенного врага, но и его модель для битвы
    func enemy(at p: Coordinates, in s: LevelState) -> (PlacedEnemy, Enemy)? {
        guard let placedEnemy = s.enemies.first(where: { $0.position == p }) else {
            return nil
        }
        return (placedEnemy, placedEnemy.model)
    }
}
