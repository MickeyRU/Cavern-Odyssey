import Foundation

/// Построитель графа связности для комнат.
/// Использует алгоритм минимального остовного дерева (MST, Minimum Spanning Tree),
/// чтобы соединить все комнаты в единый связный граф.
/// Каждое ребро соединяет две комнаты ― выбор идёт по минимальной "стоимости" (манхэттенскому расстоянию).
enum GraphConnector {
    
    /// Строит набор рёбер, соединяющих комнаты в связный граф (MST).
    ///
    /// - Parameter roomsFlat: массив из 9 комнат (3×3), сплющенный в одномерный массив.
    /// - Returns: список рёбер как пар индексов `(i, j)` по этому массиву.
    ///
    /// Алгоритм:
    /// 1. Строим список всех возможных рёбер между комнатами и назначаем вес (манхэттенское расстояние между центрами).
    /// 2. Сортируем рёбра по весу.
    /// 3. Пробегаем рёбра по порядку и добавляем их, если они соединяют разные компоненты (DSU).
    ///    Таким образом формируем минимальное остовное дерево (MST).
    static func buildEdges(roomsFlat: [Room]) -> [(Int, Int)] {
        precondition(roomsFlat.count == 9)

        // 1) Все возможные пары рёбер между комнатами
        var edges: [(i: Int, j: Int, w: Int)] = []
        for i in 0..<roomsFlat.count {
            for j in (i+1)..<roomsFlat.count {
                let w = Geom.manhattan(Geom.center(of: roomsFlat[i]),
                                       Geom.center(of: roomsFlat[j]))
                edges.append((i, j, w))
            }
        }
        
        // 2) Сортируем рёбра по возрастанию веса (короткие ― приоритетнее)
        edges.sort { $0.w < $1.w }
        
        // 3) Алгоритм Крускала: постепенно строим MST
        var dsu = DSU(n: roomsFlat.count)
        var mst: [(Int, Int)] = []
        for e in edges where mst.count < roomsFlat.count - 1 {
            if dsu.union(e.i, e.j) { // если соединяет разные компоненты
                mst.append((e.i, e.j))
            }
        }
        return mst
    }
    
    // MARK: - Вспомогательная структура Disjoint Set Union (Union-Find)

    /// Классический DSU (Union-Find) для поддержки алгоритма Крускала.
    /// Позволяет эффективно проверять, принадлежат ли вершины одному множеству.
    private struct DSU {
        var p: [Int]  // родитель
        var r: [Int]  // ранг (приблизительная высота дерева)

        init(n: Int) {
            p = Array(0..<n)
            r = .init(repeating: 0, count: n)
        }

        /// Находит представителя множества для элемента `x` (с путевой компрессией).
        mutating func find(_ x: Int) -> Int {
            p[x] == x ? x : { p[x] = find(p[x]); return p[x] }()
        }

        /// Объединяет множества, в которых находятся `a` и `b`.
        /// - Returns: `true`, если множества были разными и удалось объединить; `false`, если уже в одном.
        mutating func union(_ a: Int, _ b: Int) -> Bool {
            var a = find(a), b = find(b)
            if a == b { return false }
            if r[a] < r[b] { swap(&a, &b) }
            p[b] = a
            if r[a] == r[b] { r[a] += 1 }
            return true
        }
    }
}
