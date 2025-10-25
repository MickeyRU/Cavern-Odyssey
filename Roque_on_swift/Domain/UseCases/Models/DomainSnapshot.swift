import Foundation

struct Placed<Model> {
    let id: ActorID = .init()
    var position: Coordinates
    var model: Model
}

typealias PlacedPlayer = Placed<Character>
typealias PlacedEnemy  = Placed<Enemy>

struct DomainSnapshot {
    let canvasSize: Size
    let rooms: [Room]
    let corridors: [CorridorPath]
    let worldItems: [PlacedItem]
    let player: PlacedPlayer
    let enemies: [PlacedEnemy]
    let hud: DomainHUD
    
    let explored: Set<Coordinates>
}

struct DomainHUD {
    let weaponName: String?
    let gold: Int
    let hp: Int
    let maxHP: Int
    let depth: Int
    let inventorySummary: String
}

struct ActorID: Hashable {
    let rawValue: UUID
    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

struct PlacedItem {
    let position: Coordinates
    let item: Item
}
