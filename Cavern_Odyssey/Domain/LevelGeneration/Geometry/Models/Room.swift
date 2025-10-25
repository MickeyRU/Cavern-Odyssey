import Foundation

/// Прямоугольная комната.
/// Периметр — стены, внутренняя область — пол.
/// Валидация (что двери на периметре, размеры ≥ 3 и т.п.) — ответственность Domain.
struct Room {
    /// Левый верхний угол комнаты.
    let origin: Coordinates
    let width: Int
    let height: Int
    let doors: [Door]
}

struct Door: Equatable, Hashable {
    let position: Coordinates
    var kind: DoorKind
}

enum DoorKind: Equatable, Hashable {
    case open
    case locked(KeyColor)
}

extension Room {
    var left:   Int { origin.x }
    var top:    Int { origin.y }
    var right:  Int { origin.x + width  - 1 }
    var bottom: Int { origin.y + height - 1 }

    var innerLeft:   Int { left + 1 }
    var innerRight:  Int { right - 1 }
    var innerTop:    Int { top + 1 }
    var innerBottom: Int { bottom - 1 }

    var hasInterior: Bool { innerLeft <= innerRight && innerTop <= innerBottom }
}

extension Room {
    /// Возвращает новый Room, где дверь в точке `pos` заменена на указанную `kind`.
    func withDoor(at pos: Coordinates, kind: DoorKind) -> Room {
        var newDoors = doors
        if let i = newDoors.firstIndex(where: { $0.position == pos }) {
            newDoors[i] = Door(position: pos, kind: kind)
        }
        return Room(origin: origin, width: width, height: height, doors: newDoors)
    }
}
