import Foundation

/// Простроение коридора между ДВУМЯ дверями через A*.
/// Не залезает в комнаты/коридоры, не выходит за границы.
/// Если путь не найден — вернёт пустой CorridorPath.
enum CorridorGenerator {

    /// Построить коридор и пометить его клетки как занятые (в blocked).
    static func connect(
        doorA: Coordinates,
        doorB: Coordinates,
        worldBounds: Size,
        blocked: inout Set<Coordinates>
    ) -> CorridorPath {

        // Ищем путь
        guard let tiles = CorridorRouter.route(from: doorA, to: doorB, bounds: worldBounds, blocked: blocked)
        else {
            return CorridorPath(tiles: [])
        }

        // Занимаем клетки коридора, чтобы следующие коридоры их обходили
        for t in tiles {
            blocked.insert(t)
        }
        return CorridorPath(tiles: tiles)
    }

    /// Собирает набор «запрещённых» клеток: стены и интерьеры всех комнат + уже построенные коридоры.
    /// Исключает сами двери, чтобы можно было «войти/выйти».
    static func buildBlocked(
        rooms: [Room],
        corridors: [CorridorPath],
        except doors: Set<Coordinates>
    ) -> Set<Coordinates> {
        var s = Set<Coordinates>()

        // стены комнат
        for r in rooms {
            for x in r.left...r.right {
                s.insert(.init(x: x, y: r.top))
                s.insert(.init(x: x, y: r.bottom))
            }
            for y in r.top...r.bottom {
                s.insert(.init(x: r.left,  y: y))
                s.insert(.init(x: r.right, y: y))
            }
            // интерьер комнат
            if r.width >= 3 && r.height >= 3 {
                for y in (r.top+1)..<r.bottom {
                    for x in (r.left+1)..<r.right {
                        s.insert(.init(x: x, y: y))
                    }
                }
            }
        }

        // уже построенные коридоры
        for c in corridors {
            for p in c.tiles { s.insert(p) }
        }

        // двери можно, значит убираем их из блокировок
        for d in doors { s.remove(d) }

        return s
    }
}
