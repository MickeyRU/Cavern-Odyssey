import Foundation

/// Генератор замков и ключей без софтлоков.
/// Работает по дереву (MST): замки ставим на рёбра вдоль пути start→exit,
/// ключ к каждому замку кладём в уже достижимую (раньше по пути) комнату.
struct LockAndKeyGenerator {

    static func generate(
        rooms: [Room],
        edges: [(Int, Int)],
        doorLinks: [DoorFactory.DoorLink],
        startIndex: Int,
        exitIndex: Int
    ) -> (rooms: [Room], items: [PlacedItem]) {

        // 1) Быстрые структуры
        let adj = buildAdjacency(n: rooms.count, edges: edges)
        var linkByEdge = [EdgeKey: DoorFactory.DoorLink]()
        for l in doorLinks { linkByEdge[EdgeKey(l.i, l.j)] = l }

        // 2) Путь start→exit (BFS)
        let parent = bfsParents(from: startIndex, adj: adj)
        let path = restorePath(to: exitIndex, parent: parent)
        guard path.count >= 2 else { return (rooms, []) }

        // 3) Рёбра пути и выбор, что запирать
        let pathEdges: [(Int, Int)] = zip(path, path.dropFirst()).map { ($0, $1) }
        let candidates = Array(pathEdges.dropFirst())
        guard !candidates.isEmpty else { return (rooms, []) }

        let maxLocks = min(3, candidates.count)
        let edgesToLock = pickEvenly(candidates, count: maxLocks)

        let palette: [KeyColor] = [.red, .blue, .yellow]

        var outRooms = rooms
        var items: [PlacedItem] = []
        var occupied = Set<Coordinates>()   // занятые клетки под ключи

        // 4) Для каждого замка — ставим замок и кладём ключ РАНЬШЕ по пути
        for (idx, edge) in edgesToLock.enumerated() {
            let color = palette[idx % palette.count]
            guard let link = linkByEdge[EdgeKey(edge.0, edge.1)] else { continue }

            // Замки на обе створки
            let okA = lockDoor(in: &outRooms[edge.0], at: link.from, color: color)
            let okB = lockDoor(in: &outRooms[edge.1], at: link.to,   color: color)
            guard okA && okB else { continue }

            // Позиция ребра на пути (edge = path[i]→path[i+1])
            guard let posOnPath = pathEdges.firstIndex(where: { $0.0 == edge.0 && $0.1 == edge.1 }) else { continue }

            // Кандидаты- комнаты ДОВОльно ранние на пути (префикс), исключая саму комнату edge.0
            let prefix = Array(path.prefix(posOnPath + 1))
            let prefixExcludingEdgeRoom = prefix.filter { $0 != edge.0 && $0 != startIndex }

            // Приоритет: тупиковые среди prefix (без старта/выхода), исключая edge.0
            let leafCandidates = prefixExcludingEdgeRoom.filter {
                isLeaf($0, adj: adj, startIndex: startIndex, exitIndex: exitIndex)
            }

            // Выбор комнаты под ключ: лист → иначе любая раньше → иначе fallback на старт
            let keyRoomIndex = leafCandidates.randomElement()
                ?? prefixExcludingEdgeRoom.randomElement()
                ?? edge.0

            // Свободная клетка пола
            let keyRoom = outRooms[keyRoomIndex]
            let keyPos = pickRandomFreeFloor(in: keyRoom, occupied: &occupied) ?? Geom.center(of: keyRoom)
            occupied.insert(keyPos)

            // Итем ключа
            let keyName: String = {
                switch color {
                case .red:    return "Красный ключ"
                case .blue:   return "Синий ключ"
                case .yellow: return "Жёлтый ключ"
                }
            }()
            items.append(.init(position: keyPos,
                               item: .init(type: .key(color), name: keyName)))
        }

        return (outRooms, items)
    }

    // MARK: - Helpers

    private struct EdgeKey: Hashable {
        let a: Int, b: Int
        init(_ i: Int, _ j: Int) {
            if i < j { a = i; b = j } else { a = j; b = i }
        }
    }

    private static func buildAdjacency(n: Int, edges: [(Int, Int)]) -> [[Int]] {
        var g = Array(repeating: [Int](), count: n)
        for (u, v) in edges { g[u].append(v); g[v].append(u) }
        return g
    }

    /// BFS: родитель каждой вершины на пути от старта (или -1, если не достигнута)
    private static func bfsParents(from s: Int, adj: [[Int]]) -> [Int] {
        let n = adj.count
        var parent = Array(repeating: -1, count: n)
        var q = [Int](); q.reserveCapacity(n)
        parent[s] = s; q.append(s)
        var head = 0
        while head < q.count {
            let u = q[head]; head += 1
            for v in adj[u] where parent[v] == -1 {
                parent[v] = u
                q.append(v)
            }
        }
        return parent
    }

    /// Восстановить путь s→v, если parent строился BFS-ом от s (parent[s] == s)
    private static func restorePath(to v: Int, parent: [Int]) -> [Int] {
        guard v >= 0 && v < parent.count, parent[v] != -1 else { return [] }
        var path = [Int]()
        var cur = v
        while true {
            path.append(cur)
            if parent[cur] == cur { break }
            cur = parent[cur]
            if cur == -1 { return [] }
        }
        return path.reversed()
    }

    /// Выбрать примерно равномерно `count` рёбер из массива рёбер пути.
    private static func pickEvenly<T>(_ arr: [T], count k: Int) -> [T] {
        guard k > 0 else { return [] }
        if arr.count <= k { return arr }
        var res: [T] = []
        for i in 0..<k {
            let idx = Int(Double(i) * Double(arr.count) / Double(k))
            res.append(arr[idx])
        }
        return res
    }

    /// Заменяет kind у двери с данным положением на .locked(color)
    private static func lockDoor(in room: inout Room, at pos: Coordinates, color: KeyColor) -> Bool {
        guard let di = room.doors.firstIndex(where: { $0.position == pos }) else { return false }
        var newDoors = room.doors
        let old = newDoors[di]
        newDoors[di] = Door(position: old.position, kind: .locked(color))
        room = Room(origin: room.origin, width: room.width, height: room.height, doors: newDoors)
        return true
    }
    
    
    /// Все клетки «пола» (внутренняя область без стен) комнаты.
    private static func floorTiles(of r: Room) -> [Coordinates] {
        guard r.width >= 3, r.height >= 3 else { return [] }
        var tiles: [Coordinates] = []
        for y in (r.top+1)..<r.bottom {
            for x in (r.left+1)..<r.right {
                tiles.append(.init(x: x, y: y))
            }
        }
        return tiles
    }

    /// Случайная свободная клетка пола комнаты.
    /// - Возвращает nil, если свободных клеток нет.
    private static func pickRandomFreeFloor(in r: Room,
                                            occupied: inout Set<Coordinates>) -> Coordinates? {
        var candidates = floorTiles(of: r).shuffled()
        while let p = candidates.popLast() {
            if !occupied.contains(p) { return p }
        }
        return nil
    }
    
    /// Определяет тупиковая ли комната
    private static func isLeaf(_ i: Int, adj: [[Int]], startIndex: Int, exitIndex: Int) -> Bool {
        // Лист = степень 1; исключим старт/выход, чтобы не засорять их ключами
        if i == startIndex || i == exitIndex { return false }
        return adj[i].count == 1
    }
}
