import Foundation

struct DomainSnapshotDTO: Codable {
    let canvasSize: SizeDTO
    let rooms: [RoomDTO]
    let corridors: [CorridorPathDTO]
    let worldItems: [PlacedItemCodable]
    let player: PlacedPlayerDTO
    let enemies: [PlacedEnemyDTO]
    let hud: DomainHUDDTO
    
    let explored: [CoordinatesDTO]
}
struct GameSessionDTO: Codable {
    let player: CharacterDTO
    let depth: Int
}

struct PlacedItemCodable: Codable {
    let position: CoordinatesDTO
    let item: ItemCodable
}

struct ItemCodable: Codable {
    let name: String
    let kind: ItemKindCodable
}

enum ItemKindCodable: Codable {
    case weapon
    case food
    case potion
    case scroll
    case treasure
    case key(KeyColorCodable)
    case exit
}

enum KeyColorCodable: String, Codable {
    case red
    case blue
    case yellow
}

struct SizeDTO: Codable {
    let width: Int
    let height: Int
}

struct CoordinatesDTO: Codable {
    let x: Int
    let y: Int
}

struct RoomDTO: Codable {
    let origin: CoordinatesDTO
    let width: Int
    let height: Int
    let doors: [DoorDTO]
}
struct DoorDTO: Codable {
    let position: CoordinatesDTO
    let kind: DoorKindCodable
}

enum DoorKindCodable: Codable {
    case open
    case locked(KeyColorCodable)

    enum CodingKeys: String, CodingKey {
        case type, color
    }

    init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    switch type {
        case "open":
        self = .open
        case "locked":
        let color = try container.decode(KeyColorCodable.self, forKey: .color)
        self = .locked(color)
        default:
        throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown door kind")
        }
    }
    func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
        case .open:
        try container.encode("open", forKey: .type)
        case .locked(let color):
        try container.encode("locked", forKey: .type)
        try container.encode(color, forKey: .color)
        }
    }
}

struct CorridorPathDTO: Codable {
    let tiles: [CoordinatesDTO]
}

struct PlacedDTO<Model: Codable>: Codable {
    let id: ActorIDDTO
    let position: CoordinatesDTO
    let model: Model
}

struct ActorIDDTO: Codable, Hashable {
    let rawValue: UUID
}

struct DomainHUDDTO: Codable {
    let weaponName: String?
    let gold: Int
    let hp: Int
    let maxHP: Int
    let depth: Int
    let inventorySummary: String
}

struct CharacterDTO: Codable {
    let avatar: String
    let name: String
    let maxHealth: Int
    let currentHealth: Int
    let dexterity: Int
    let strength: Int
    let gold: Int
    let skipAttack: Bool
    var currentWeapon: ItemCodable?
    var inventory: InventoryDTO
    var statusEffects: [StatusEffectDTO] = []
}

struct InventoryDTO: Codable {
    var items: [ItemCodable] = []
}

struct EnemyDTO: Codable {
    let type: EnemyTypeDTO
    var avatar: String
    var name: String
    var maxHealth: Int
    var currentHealth: Int
    var dexterity: Int
    var strength: Int
    var gold: Int
    var hostility: HostilityDTO
    var effects: [SpecialEffectDTO]
    var statusEffects: [StatusEffectDTO] = []
    var lastPosition: CoordinatesDTO?
    var evasionUsed: Bool = false
    var isInvisible: Bool
    var isDisguised: Bool = true
}

enum StatusEffectDTO: Codable {
    case sleep(duration: Int)
    case invisible(duration: Int)
    case rest(duration: Int)
    case evasion(duration: Int)
    
    // для применения Items
    case buffStrength(amount: Int, duration: Int)
    case buffDexterity(amount: Int, duration: Int)
    case buffMaxHealth(amount: Int, duration: Int)
}
enum SpecialEffectDTO: String, Codable {
    case lifeDrain
    case invisibility
    case rest
    case sleep

    var effect: Effect {
        switch self {
        case .lifeDrain: return LifeDrainEffect()
        case .invisibility: return InvisibilityEffect()
        case .rest: return RestEffect()
        case .sleep: return SleepEffect()
        }
    }

    static func fromEffect(_ effect: Effect) -> SpecialEffectDTO? {
        switch effect {
        case is LifeDrainEffect: return .lifeDrain
        case is InvisibilityEffect: return .invisibility
        case is RestEffect: return .rest
        case is SleepEffect: return .sleep
        default: return nil
        }
    }
}


protocol EffectDTO: Codable {
    var timing: EffectTimingDTO { get }
}

enum EffectTimingDTO: Codable {
    case beforeAttack
    case afterAttack
}

enum EnemyTypeDTO: String, Codable {
    case zombie
    case vampire
    case ghost
    case ogre
    case snakeMage
    case mimic
}

enum HostilityDTO: String, Codable {
    case noagro
    case hostile
    case aggressive
    case passive
    
    var aggroRadius: Int {
        switch self {
        case .noagro: return 0
        case .passive: return 1
        case .hostile: return 3
        case .aggressive: return 5
        }
    }
}

typealias PlacedPlayerDTO = PlacedDTO<CharacterDTO>
typealias PlacedEnemyDTO = PlacedDTO<EnemyDTO>
