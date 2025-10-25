import Foundation

// MARK: - План генерации

/// Внутренняя «чертёжка» пайплайна генерации уровня.
/// Живёт только в слое LevelGeneration.
struct LevelGenerationPlan {
    // Входные/базовые данные
    var canvasSize: Size

    // Геометрия
    var rooms: [Room] = []                       // плоский 3×3 (count == 9)
    var edges: [(Int, Int)] = []                 // рёбра графа комнат (индексы во flat rooms)
    var doorLinks: [DoorFactory.DoorLink] = []   // пары дверей для каждого ребра
    var corridors: [CorridorPath] = []           // итоговые коридоры

    // Логика геймплея
    var startIndex: Int = 0                      // индекс стартовой комнаты
    var exitIndex: Int? = nil                    // индекс выходной комнаты
    var items: [PlacedItem] = []                 // предметы на полу (включая ключи)
    var enemies: [PlacedEnemy] = []              // расставленные враги
    var player: PlacedPlayer? = nil
    
    // Удобные геттеры
    var hasGrid3x3: Bool { rooms.count == 9 }
    var roomsGrid3x3: [[Room]] {
        guard hasGrid3x3 else { return [] }
        return stride(from: 0, to: rooms.count, by: 3).map { Array(rooms[$0..<$0+3]) }
    }
}
