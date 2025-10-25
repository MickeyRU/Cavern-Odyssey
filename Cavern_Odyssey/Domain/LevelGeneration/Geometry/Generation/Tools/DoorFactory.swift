import Foundation

/// Фабрика дверей: ставит двери только для указанных пар комнат
/// и возвращает пары дверей, которые нужно соединить коридорами.
enum DoorFactory {

    struct DoorLink {
        let i: Int           // индекс комнаты A во flat-массиве (0...8)
        let j: Int           // индекс комнаты B во flat-массиве (0...8)
        let from: Coordinates // дверь на периметре комнаты i
        let to: Coordinates   // дверь на периметре комнаты j
    }

    /// grid 3×3 + рёбра (по индексам flat) →
    ///   - обновлённая решётка с добавленными дверями
    ///   - список DoorLink для CorridorBuilder
    static func addDoors(for grid: [[Room]], edges: [(Int, Int)]) -> (grid: [[Room]], links: [DoorLink]) {
        precondition(grid.count == 3 && grid.allSatisfy { $0.count == 3 })

        var flat = grid.flatMap { $0 }  // 9 комнат
        var links: [DoorLink] = []

        for (i, j) in edges {
            let a = flat[i], b = flat[j]
            let (doorA, doorB) = pickDoorPair(a, b)

            // вставляем двери в обе комнаты (без дублей)
            flat[i] = withDoor(doorA, in: a)
            flat[j] = withDoor(doorB, in: b)

            links.append(.init(i: i, j: j, from: doorA, to: doorB))
        }

        // обратно в 3×3
        let gridBack = stride(from: 0, to: flat.count, by: 3).map { Array(flat[$0..<$0+3]) }
        return (gridBack, links)
    }

    // MARK: - helpers

    /// Подбираем пару дверей на периметрах A и B.
    /// Стараемся ставить напротив, не попадаем в углы (используем inner-диапазоны).
    private static func pickDoorPair(_ a: Room, _ b: Room) -> (Coordinates, Coordinates) {
        let ca = Geom.center(of: a)
        let cb = Geom.center(of: b)
        let dx = abs(cb.x - ca.x), dy = abs(cb.y - ca.y)

        if dx >= dy {
            // горизонтальная пара: правая у левого, левая у правого
            let ya = Geom.innerYRange(a), yb = Geom.innerYRange(b)
            let inter = Geom.intersection(ya, yb)
            let yBase = (ca.y + cb.y) / 2
            let y = inter.map { Geom.clamp(yBase, $0.lowerBound, $0.upperBound) }
                 ?? Geom.clamp(yBase, min(ya.lowerBound, yb.lowerBound), max(ya.upperBound, yb.upperBound))
            let aDoor = Coordinates(x: (cb.x >= ca.x) ? a.right : a.left, y: Geom.clamp(y, ya.lowerBound, ya.upperBound))
            let bDoor = Coordinates(x: (cb.x >= ca.x) ? b.left  : b.right, y: Geom.clamp(y, yb.lowerBound, yb.upperBound))
            return (aDoor, bDoor)
        } else {
            // вертикальная пара: нижняя у верхнего, верхняя у нижнего
            let xa = Geom.innerXRange(a), xb = Geom.innerXRange(b)
            let inter = Geom.intersection(xa, xb)
            let xBase = (ca.x + cb.x) / 2
            let x = inter.map { Geom.clamp(xBase, $0.lowerBound, $0.upperBound) }
                 ?? Geom.clamp(xBase, min(xa.lowerBound, xb.lowerBound), max(xa.upperBound, xb.upperBound))
            let aDoor = Coordinates(x: Geom.clamp(x, xa.lowerBound, xa.upperBound), y: (cb.y >= ca.y) ? a.bottom : a.top)
            let bDoor = Coordinates(x: Geom.clamp(x, xb.lowerBound, xb.upperBound), y: (cb.y >= ca.y) ? b.top    : b.bottom)
            return (aDoor, bDoor)
        }
    }

    private static func withDoor(_ p: Coordinates, in r: Room) -> Room {
        if r.doors.contains(where: { $0.position == p }) { return r }
        var ds = r.doors
        ds.append(Door(position: p, kind: .open))
        return Room(origin: r.origin, width: r.width, height: r.height, doors: ds)
    }
}
