import Foundation

/// Простой сервис под размещение объектов ВНУТРИ КОНКРЕТНОЙ КОМНАТЫ.
/// Истина одна: занято только тем, что уже лежит в plan.items / plan.enemies.
struct RoomPlacementService {

    /// Первая свободная клетка пола комнаты (детерминированно, скан слева-направо, сверху-вниз).
    static func firstFreeFloor(in plan: LevelGenerationPlan, roomIndex: Int) -> Coordinates? {
        guard let r = plan.rooms[safe: roomIndex] else { return nil }
        let occ = occupiedSet(in: plan, room: r)
        for y in (r.top+1)..<r.bottom {
            for x in (r.left+1)..<r.right {
                let p = Coordinates(x: x, y: y)
                if !occ.contains(p) { return p }
            }
        }
        return nil
    }

    /// Случайная свободная клетка пола комнаты (перемешиваем кандидатов).
    static func randomFreeFloor<R: RandomNumberGenerator>(
        in plan: LevelGenerationPlan,
        roomIndex: Int,
        rng: inout R
    ) -> Coordinates? {
        guard let r = plan.rooms[safe: roomIndex] else { return nil }
        let occ = occupiedSet(in: plan, room: r)
        var candidates: [Coordinates] = []
        candidates.reserveCapacity(max(0, (r.right - r.left - 1) * (r.bottom - r.top - 1)))
        for y in (r.top+1)..<r.bottom {
            for x in (r.left+1)..<r.right {
                let p = Coordinates(x: x, y: y)
                if !occ.contains(p) { candidates.append(p) }
            }
        }
        candidates.shuffle(using: &rng)
        return candidates.first
    }

    /// Множество занятых клеток ВНУТРИ `room` (по items и enemies).
    private static func occupiedSet(in plan: LevelGenerationPlan, room: Room) -> Set<Coordinates> {
        var s = Set<Coordinates>()
        // items
        for it in plan.items {
            let p = it.position
            if isInsideInnerFloor(p, room) { s.insert(p) }
        }
        // enemies
        for en in plan.enemies {
            let p = en.position
            if isInsideInnerFloor(p, room) { s.insert(p) }
        }
        return s
    }

    /// Проверка «точка на полу (без стен) этой комнаты».
    private static func isInsideInnerFloor(_ p: Coordinates, _ r: Room) -> Bool {
        p.x > r.left && p.x < r.right && p.y > r.top && p.y < r.bottom
    }
}

// safe-индекс
private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
