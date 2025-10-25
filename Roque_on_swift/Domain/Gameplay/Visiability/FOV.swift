import Foundation

// MARK: - Видимость и «туман войны»

/// Текущее состояние видимости:
/// - `visible`: клетки, видимые в текущем кадре (что игрок видит прямо сейчас);
/// - `seen`: клетки, которые когда-либо попадали в поле зрения (запоминаем в рамках уровня).
struct VisibilityMap {
    var visible: Set<Coordinates> = []
    var seenByLevel: Set<Coordinates> = []

    mutating func clearFor(level: Int) {
        visible.removeAll()
        seenByLevel.removeAll()
    }
}

// MARK: - Проверки геометрии уровня (локальные хелперы, используются только FOV)

/// Является ли клетка дверью любой из комнат мира.
private func isDoor(_ p: Coordinates, in world: GameWorldSnapshot) -> Bool {
    doorAt(p, in: world) != nil
}

private func doorAt(_ p: Coordinates, in world: GameWorldSnapshot) -> DoorSnapshot? {
    for r in world.rooms {
        if let d = r.doors.first(where: { $0.position == p }) { return d }
    }
    return nil
}

private func isLockedDoor(_ p: Coordinates, in world: GameWorldSnapshot) -> Bool {
    guard let d = doorAt(p, in: world) else { return false }
    if case .locked = d.kind { return true }
    return false
}

/// Является ли клетка стеной комнаты.
/// Важно: дверь не считается стеной (мы «видим сквозь дверь» как сквозь проём).
private func isWall(_ p: Coordinates, in world: GameWorldSnapshot) -> Bool {
    for r in world.rooms {
        // вертикальные стены
        if (p.x == r.left || p.x == r.right), (r.top...r.bottom).contains(p.y) {
            return !isDoor(p, in: world) // дверь на стене — НЕ стена
        }
        // горизонтальные стены
        if (p.y == r.top  || p.y == r.bottom), (r.left...r.right).contains(p.x) {
            return !isDoor(p, in: world)
        }
    }
    return false
}

/// Непрозрачность клетки для FOV:
/// - всё за пределами канваса — непрозрачно;
/// - стены — непрозрачны (двери — нет).
private func isOpaque(_ p: Coordinates, in world: GameWorldSnapshot) -> Bool {
    if p.x < 0 || p.y < 0 || p.x >= world.canvasSize.width || p.y >= world.canvasSize.height { return true }
    return isWall(p, in: world) || isLockedDoor(p, in: world)
}

/// Возвращает комнату, в которой находится игрок (если находится).
/// Проверяем строгую внутренность — периметр комнаты не считается «внутри».
private func playerRoom(_ player: Coordinates, in world: GameWorldSnapshot) -> RoomSnapshot? {
    for r in world.rooms where (player.x > r.left && player.x < r.right && player.y > r.top && player.y < r.bottom) {
        return r
    }
    return nil
}

/// Полностью «раскрывает» комнату: стены, пол и двери.
/// Используется, чтобы внутренняя комната целиком была видна, если игрок в ней стоит.
private func revealRoom(_ r: RoomSnapshot, into set: inout Set<Coordinates>) {
    // периметр
    for x in r.left...r.right {
        set.insert(.init(x: x, y: r.top))
        set.insert(.init(x: x, y: r.bottom))
    }
    for y in r.top...r.bottom {
        set.insert(.init(x: r.left,  y: y))
        set.insert(.init(x: r.right, y: y))
    }
    // пол (только если есть внутренняя область)
    if r.width >= 3 && r.height >= 3 {
        for y in (r.top+1)..<r.bottom {
            for x in (r.left+1)..<r.right { set.insert(.init(x: x, y: y)) }
        }
    }
    // двери
    for d in r.doors { set.insert(d.position) }
}

// MARK: - Брезенхэм: дискретная прямая между двумя клетками
/// Классическая integer-реализация алгоритма Брезенхэма.
/// Используем для трассировки «лучей» видимости от игрока к целевой клетке.
private func bresenhamLine(from a: Coordinates, to b: Coordinates) -> [Coordinates] {
    var x0 = a.x, y0 = a.y
    let x1 = b.x, y1 = b.y
    
    var points: [Coordinates] = []
    let dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1
    let dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1
    var err = dx + dy
    
    while true {
        points.append(.init(x: x0, y: y0))
        if x0 == x1 && y0 == y1 { break }
        let e2 = 2 * err
        if e2 >= dy { err += dy; x0 += sx }
        if e2 <= dx { err += dx; y0 += sy }
    }
    return points
}

// MARK: - Правила трассировки лучей (борьба с «подглядыванием за угол» и логика дверей)

/// Запрещаем «диагональный» проход луча между двумя смежными стенами (corner-blocking):
/// если следующий шаг диагональный, а по одной из осей между клетками стоит непрозрачная клетка,
/// луч здесь обрываем — это устраняет подгляд через угол.
private func blocksDiagonal(prev: Coordinates, next: Coordinates, world: GameWorldSnapshot) -> Bool {
    if abs(next.x - prev.x) == 1 && abs(next.y - prev.y) == 1 {
        let a = Coordinates(x: prev.x, y: next.y) // «вертикальный» сосед
        let b = Coordinates(x: next.x, y: prev.y) // «горизонтальный» сосед
        if isOpaque(a, in: world) || isOpaque(b, in: world) { return true }
    }
    return false
}

/// Ось дверного проёма: нужна, чтобы лучи «проходили через щель двери» только по оси проёма.
private enum DoorAxis { case verticalWall, horizontalWall }

/// Строим быстрые структуры:
/// - множество всех дверей;
/// - словарь {дверь → ось проёма}, чтобы понимать, по какой оси разрешён проход луча.
private func buildDoorMaps(for world: GameWorldSnapshot) -> (set: Set<Coordinates>, axis: [Coordinates: DoorAxis]) {
    var s = Set<Coordinates>()
    var m: [Coordinates: DoorAxis] = [:]
    for r in world.rooms {
        for d in r.doors {
            let p = d.position
            s.insert(p)
            if p.x == r.left || p.x == r.right { m[p] = .verticalWall }   // дверь на вертикальной стене: фиксируем Y
            else { m[p] = .horizontalWall }                                // дверь на горизонтальной стене: фиксируем X
        }
    }
    return (s, m)
}

/// Если рядом с текущей клеткой есть дверь, ограничиваем луч по оси дверного проёма:
/// - для двери на вертикальной стене луч должен идти строго по одной Y-строке (y == door.y);
/// - для двери на горизонтальной стене — строго по одному X-столбцу (x == door.x).
private func blocksNearDoor(prev: Coordinates,
                            next: Coordinates,
                            doorSet: Set<Coordinates>,
                            doorAxis: [Coordinates: DoorAxis]) -> Bool {
    // 4 клетки по кресту вокруг prev
    let nbs = [
        Coordinates(x: prev.x + 1, y: prev.y),
        Coordinates(x: prev.x - 1, y: prev.y),
        Coordinates(x: prev.x,     y: prev.y + 1),
        Coordinates(x: prev.x,     y: prev.y - 1),
    ]
    for d in nbs where doorSet.contains(d) {
        if let axis = doorAxis[d] {
            switch axis {
            case .verticalWall:
                // дверь на вертикальной стене → держим луч на одной Y-строке
                if next.y != d.y { return true }
            case .horizontalWall:
                // дверь на горизонтальной стене → держим луч на одном X-столбце
                if next.x != d.x { return true }
            }
        }
    }
    return false
}

/// После того как луч прошёл через дверь (или стартовал из клетки-двери),
/// «фиксируем» соответствующую ось до тех пор, пока луч не столкнётся с препятствием.
private func lockedAxis(afterDoor door: Coordinates, world: GameWorldSnapshot) -> (lockX: Int?, lockY: Int?) {
    for r in world.rooms {
        if r.doors.contains(where: { $0.position == door }) {
            if door.x == r.left || door.x == r.right { return (nil, door.y) }   // дверь в вертикальной стене → фиксируем Y
            if door.y == r.top  || door.y == r.bottom { return (door.x, nil) }  // дверь в горизонтальной стене → фиксируем X
        }
    }
    return (nil, nil)
}

// MARK: - Основной API FOV

/// Расчёт поля зрения (field of view):
/// - Ray casting лучами по сетке (через Брезенхэма);
/// - запрет диагонального «подсмотра» за угол (corner-blocking);
/// - «щель дверей»: рядом с дверью лучи идут только по оси проёма; после входа в дверь — ось фиксируется;
/// - комната, в которой стоит игрок, всегда полностью «раскрывается»;
/// - в коридоре мы не подсвечиваем чужие стены (cut-off по стенам).
enum FOV {
    static func compute(from player: Coordinates,
                        world: GameWorldSnapshot,
                        radius: Int) -> VisibilityMap {
        var vis = VisibilityMap()
        vis.visible.insert(player)
        
        // Случай, когда игрок в коридоре (не внутри комнаты):
        // Рисуем простые «крестовые» лучи по четырём осям без полного ray casting —
        // и не подсвечиваем чужие стены (столкнулись со стеной — остановились).
        if playerRoom(player, in: world) == nil {
            let dirs = [(1,0), (-1,0), (0,1), (0,-1)]
            for (dx, dy) in dirs {
                var x = player.x
                var y = player.y
                var step = 0
                while step < radius {
                    x += dx; y += dy; step += 1
                    if x < 0 || y < 0 || x >= world.canvasSize.width || y >= world.canvasSize.height { break }
                    let p = Coordinates(x: x, y: y)
                    
                    // В коридоре стены не «подсматриваем» — луч обрываем, не добавляя стену.
                    if isWall(p, in: world) { break }
                    
                    // Двери подсвечиваем (их увидеть важно).
                    vis.visible.insert(p)
                    
                    // На любом непрозрачном (стена/граница) — стоп.
                    if isOpaque(p, in: world) { break }
                }
            }
            return vis
        }
        
        // Полноценный ray casting, если игрок находится внутри комнаты
        // (видимость ведём во все стороны с учётом дверей и углов).
        let (doorSet, doorAxis) = buildDoorMaps(for: world)
        
        // Ограничим прямоугольником радиуса, чтобы не гонять лишние лучи.
        let r2 = radius * radius
        let minX = max(0, player.x - radius)
        let maxX = min(world.canvasSize.width  - 1, player.x + radius)
        let minY = max(0, player.y - radius)
        let maxY = min(world.canvasSize.height - 1, player.y + radius)
        
        for y in minY...maxY {
            for x in minX...maxX {
                let dx = x - player.x, dy = y - player.y
                if dx*dx + dy*dy > r2 { continue } // вне круга радиуса
                
                // Луч от игрока к целевой клетке
                let ray = bresenhamLine(from: player, to: .init(x: x, y: y))
                var prev = player
                var lockX: Int? = nil
                var lockY: Int? = nil
                
                for cell in ray.dropFirst() {
                    // не даём «подсматривать» за диагональный угол
                    if blocksDiagonal(prev: prev, next: cell, world: world) { break }
                    // рядом с дверью — луч только по оси дверного проёма
                    if blocksNearDoor(prev: prev, next: cell, doorSet: doorSet, doorAxis: doorAxis) { break }
                    
                    if isDoor(cell, in: world) {
                        // дверь видим в любом случае
                        vis.visible.insert(cell)
                        // если ЗАКРЫТА — дальше луч НЕ идёт
                        if isLockedDoor(cell, in: world) { break }
                        // если ОТКРЫТА — применяем прежнюю осевую логику
                        
                        if let axis = doorAxis[cell] {
                            switch axis {
                            case .verticalWall:
                                // в вертикальной двери вход возможен только вдоль строки
                                if prev.y != cell.y { break }
                                lockY = cell.y
                            case .horizontalWall:
                                // в горизонтальной двери — только вдоль столбца
                                if prev.x != cell.x { break }
                                lockX = cell.x
                            }
                        }
                    }
                    
                    // если предыдущая клетка была дверью — после неё фиксируем ось
                    if isDoor(prev, in: world), lockX == nil && lockY == nil {
                        (lockX, lockY) = lockedAxis(afterDoor: prev, world: world)
                    }
                    if let lx = lockX, cell.x != lx { break }
                    if let ly = lockY, cell.y != ly { break }
                    
                    vis.visible.insert(cell)
                    if isOpaque(cell, in: world) { break } // упёрлись в стену — дальше не видно
                    
                    prev = cell
                }
            }
        }
        
        // Комната, где стоит игрок, всегда видна полностью: стены, пол и двери.
        if let r = playerRoom(player, in: world) {
            revealRoom(r, into: &vis.visible)
        }
        return vis
    }
}
