import Foundation

struct GameFrameDTO {
    let world: GameWorldSnapshot
    let actors: ActorsSnapshot
    let hud: HUDSnapshot
}

struct GameWorldSnapshot {
    let canvasSize: Size
    let rooms: [RoomSnapshot]
    let corridors: [CorridorPath]
    let items: [PlacedItemDTO]
    
    let explored: Set<Coordinates>
}

struct RoomSnapshot {
    let origin: Coordinates
    let width: Int
    let height: Int
    let doors: [DoorSnapshot]
}

struct DoorSnapshot {
    let position: Coordinates
    let kind: DoorKindDTO
}

enum DoorKindDTO {
    case open
    case locked(KeyColorDTO)
}

struct PlacedItemDTO {
    let position: Coordinates
    let item: ItemDTO
}

struct ActorsSnapshot {
    let player: PlayerSnapshot
    let enemies: [EnemySnapshot]
}

struct HUDSnapshot {
    let weaponName: String?
    let gold: Int
    let hp: Int
    let maxHp: Int
    let lvl: Int
    let dex: Int
    let str: Int
}

struct EnemySnapshot {
    let id: ActorID
    let name: String
    let avatar: String
    let position: Coordinates
    let isInvisible: Bool
    let isDisguised: Bool
}

struct PlayerSnapshot {
    let id: ActorID
    let name: String
    let avatar: String
    let position: Coordinates
    let inventory: InventorySnapshot
}

struct InventorySnapshot {
    let weapons:  [ItemDTO]
    let foods:    [ItemDTO]
    let potions:  [ItemDTO]
    let scrolls:  [ItemDTO]
    let treasures:[ItemDTO]
    let equippedWeaponIndex: Int?
}

struct ItemDTO {
    let name: String
    let kind: ItemKindDTO
}

enum ItemKindDTO {
    case weapon
    case food
    case potion
    case scroll
    case treasure
    case key(KeyColorDTO)
    case exit
}

enum KeyColorDTO {
    case red
    case blue
    case yellow
}

extension RoomSnapshot {
    var left:   Int { origin.x }
    var top:    Int { origin.y }
    var right:  Int { origin.x + width  - 1 }
    var bottom: Int { origin.y + height - 1 }
}
