import Foundation

/// Поиск пути на сетке 4-направлениями (A*), без выхода за пределы
/// и без захода на «заблокированные» клетки.
enum CorridorRouter {
    /// Вернёт путь БЕЗ стартовой клетки, НО с конечной.
    static func route(
        from start: Coordinates,
        to goal: Coordinates,
        bounds: Size,
        blocked: Set<Coordinates>
    ) -> [Coordinates]? {
        struct Node: Hashable { let x: Int; let y: Int }
        func h(_ a: Node, _ b: Node) -> Int { abs(a.x - b.x) + abs(a.y - b.y) }

        let s = Node(x: start.x, y: start.y)
        let g = Node(x: goal.x,  y: goal.y)

        // старт/финиш всегда разрешаем (даже если в blocked),
        // потому что они — двери.
        func passable(_ n: Node) -> Bool {
            if (n.x == s.x && n.y == s.y) || (n.x == g.x && n.y == g.y) { return true }
            return n.x >= 0 && n.y >= 0 && n.x < bounds.width && n.y < bounds.height
                && !blocked.contains(.init(x: n.x, y: n.y))
        }

        var open = Set([s])
        var came: [Node: Node] = [:]
        var gScore: [Node: Int] = [s: 0]
        var fScore: [Node: Int] = [s: h(s, g)]

        // простая очередь на базе массива (для размеров нашего мира ок)
        while !open.isEmpty {
            // узел с минимальным fScore
            let current = open.min { (fScore[$0] ?? .max) < (fScore[$1] ?? .max) }!
            if current == g {
                // восстановим путь
                var path: [Node] = []
                var cur = current
                while let prev = came[cur] {
                    path.append(cur)
                    cur = prev
                }
                // path сейчас от goal→…→(start+1); развернём и спроецируем
                path.reverse()
                return path.map { Coordinates(x: $0.x, y: $0.y) }
            }

            open.remove(current)
            let neighs = [
                Node(x: current.x + 1, y: current.y),
                Node(x: current.x - 1, y: current.y),
                Node(x: current.x,     y: current.y + 1),
                Node(x: current.x,     y: current.y - 1),
            ].filter(passable)

            for nb in neighs {
                let tentG = (gScore[current] ?? .max) + 1
                if tentG < (gScore[nb] ?? .max) {
                    came[nb] = current
                    gScore[nb] = tentG
                    fScore[nb] = tentG + h(nb, g)
                    open.insert(nb)
                }
            }
        }
        return nil
    }
}
