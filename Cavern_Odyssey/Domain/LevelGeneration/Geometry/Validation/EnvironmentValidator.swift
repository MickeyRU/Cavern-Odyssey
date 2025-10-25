import Foundation

private func isOnPerimeter(_ p: Coordinates, of r: Room) -> Bool {
    let x0 = r.origin.x, y0 = r.origin.y
    let x1 = x0 + r.width - 1, y1 = y0 + r.height - 1
    let onX = (p.x == x0 || p.x == x1) && (p.y >= y0 && p.y <= y1)
    let onY = (p.y == y0 || p.y == y1) && (p.x >= x0 && p.x <= x1)
    return onX || onY
}

private enum SnapshotError: Error, CustomStringConvertible {
    case doorNotOnPerimeter(room: Room, door: Coordinates)
    case corridorNotEndingAtDoor(corridorIndex: Int, end: Coordinates)

    var description: String {
        switch self {
        case let .doorNotOnPerimeter(_, d):
            return "Door not on room perimeter at (\(d.x),\(d.y))"
        case let .corridorNotEndingAtDoor(i, end):
            return "Corridor[\(i)] does not end at a door (ends at \(end.x),\(end.y))"
        }
    }
}

enum EnvironmentValidator {
    static func validate(_ snap: GeometrySnapshot) throws {
        for r in snap.rooms {
            for d in r.doors where !isOnPerimeter(d.position, of: r) {
                throw SnapshotError.doorNotOnPerimeter(room: r, door: d.position)
            }
        }
        let doors = Set(snap.rooms.flatMap { $0.doors.map { $0.position } })
        for (i, c) in snap.corridors.enumerated() {
            guard let last = c.tiles.last, doors.contains(last) else {
                throw SnapshotError.corridorNotEndingAtDoor(
                    corridorIndex: i,
                    end: c.tiles.last ?? .init(x: -1, y: -1)
                )
            }
        }
    }

    /// «Прищёлкивает» коридоры к дверям, если упёрлись в стену рядом.
    static func snapped(_ snap: GeometrySnapshot) -> GeometrySnapshot {
        let doors = Set(snap.rooms.flatMap { $0.doors.map { $0.position } })
        let fixed: [CorridorPath] = snap.corridors.map { c in
            guard let end = c.tiles.last else { return c }
            if doors.contains(end) { return c }
            let nbs = [
                Coordinates(x: end.x+1, y: end.y),
                Coordinates(x: end.x-1, y: end.y),
                Coordinates(x: end.x,   y: end.y+1),
                Coordinates(x: end.x,   y: end.y-1),
            ]
            if let door = nbs.first(where: { doors.contains($0) }) {
                var t = c.tiles; _ = t.popLast(); t.append(door)
                return CorridorPath(tiles: t)
            }
            return c
        }
        return GeometrySnapshot(canvasSize: snap.canvasSize, rooms: snap.rooms, corridors: fixed)
    }
}
