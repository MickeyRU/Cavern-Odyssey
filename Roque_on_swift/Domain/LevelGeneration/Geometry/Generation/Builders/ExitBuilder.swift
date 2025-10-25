import Foundation

enum ExitBuilder: PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan { apply(to: plan) }

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        var p = plan
        let n = p.rooms.count
        guard n > 0, !p.edges.isEmpty else { return p }

        // --- BFS от старта ---
        var dist = Array(repeating: -1, count: n)
        var q = [Int]()
        q.append(p.startIndex)
        dist[p.startIndex] = 0
        var head = 0
        while head < q.count {
            let u = q[head]; head += 1
            for (a,b) in p.edges {
                let v = (a == u) ? b : (b == u ? a : -1)
                if v >= 0, dist[v] == -1 {
                    dist[v] = dist[u] + 1
                    q.append(v)
                }
            }
        }

        // Самая дальняя достижимая комната
        let candidates = (0..<n).filter { dist[$0] >= 0 }
        let farthest = candidates.max(by: { dist[$0] < dist[$1] }) ?? p.startIndex
        p.exitIndex = farthest

        // размещаем предмет .exit в этой комнате
        var rng = SystemRandomNumberGenerator()
        if let pos = RoomPlacementService.randomFreeFloor(in: p, roomIndex: farthest, rng: &rng) {
            p.items.append(PlacedItem(position: pos,
                                      item: .init(type: .exit, name: "Выход")))
        }

        return p
    }
}
