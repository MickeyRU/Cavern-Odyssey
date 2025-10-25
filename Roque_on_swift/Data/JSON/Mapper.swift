import Foundation
class CoordinatesMapper {
    static func toDTO(from domain: Coordinates) -> CoordinatesDTO {
        return CoordinatesDTO(x: domain.x, y: domain.y)
    }
    
    static func toDomain(from dto: CoordinatesDTO) -> Coordinates {
        return Coordinates(x: dto.x, y: dto.y)
    }
}

class GameSessionMapper {
    static func toDTO(from domain: GameSession) -> GameSessionDTO {
        return GameSessionDTO(
            player: CharacterMapper.toDTO(from: domain.player),
            depth: domain.depth
        )
    }
    
    static func toDomain(from dto: GameSessionDTO) -> GameSession {
        return GameSession(
            player: CharacterMapper.toDomain(from: dto.player),
            depth: dto.depth
        )
    }
}

class SizeMapper {
    static func toDTO(from domain: Size) -> SizeDTO {
        return SizeDTO(width: domain.width, height: domain.height)
    }
    
    static func toDomain(from dto: SizeDTO) -> Size {
        return Size(width: dto.width, height: dto.height)
    }
}

class DoorMapper {
    static func toDTO(from domain: Door) -> DoorDTO {
        return DoorDTO(
            position: CoordinatesMapper.toDTO(from: domain.position),
            kind: toDTO(from: domain.kind)
        )
    }
    
    static func toDomain(from dto: DoorDTO) -> Door {
        return Door(
            position: CoordinatesMapper.toDomain(from: dto.position),
            kind: toDomain(from: dto.kind)
        )
    }
    
    
    private static func toDTO(from domain: DoorKind) -> DoorKindCodable {
        switch domain {
        case .open:
            return .open
        case .locked(let color):
            return .locked(toDTO(from: color))
        }
    }
    
    
    private static func toDomain(from dto: DoorKindCodable) -> DoorKind {
        switch dto {
        case .open:
            return .open
        case .locked(let color):
            return .locked(toDomain(from: color))
        }
    }
    
    
    private static func toDTO(from domain: KeyColor) -> KeyColorCodable {
        switch domain {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        }
    }
    
    
    private static func toDomain(from dto: KeyColorCodable) -> KeyColor {
        switch dto {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        }
    }
    
    static func toDomain(from dto: CoordinatesDTO) -> Coordinates {
        return Coordinates(x: dto.x, y: dto.y)
    }
}

class RoomMapper {
    static func toDTO(from domain: Room) -> RoomDTO {
        return RoomDTO(
            origin: CoordinatesMapper.toDTO(from: domain.origin),
            width: domain.width,
            height: domain.height,
            doors: domain.doors.map(DoorMapper.toDTO)
        )
    }
    
    static func toDomain(from dto: RoomDTO) -> Room {
        return Room(
            origin: CoordinatesMapper.toDomain(from: dto.origin),
            width: dto.width,
            height: dto.height,
            doors: dto.doors.map(DoorMapper.toDomain))
    }
}


class CorridorPathMapper {
    static func toDTO(from domain: CorridorPath) -> CorridorPathDTO {
        return CorridorPathDTO(tiles: domain.tiles.map(CoordinatesMapper.toDTO))
    }
    
    static func toDomain(from dto: CorridorPathDTO) -> CorridorPath {
        return CorridorPath(tiles: dto.tiles.map(CoordinatesMapper.toDomain))
    }
}

class ActorIDMapper {
    static func toDTO(from domain: ActorID) -> ActorIDDTO {
        return ActorIDDTO(rawValue: domain.rawValue)
    }
    
    static func toDomain(from dto: ActorIDDTO) -> ActorID {
        return ActorID(dto.rawValue)
    }
}

class CharacterMapper {
    static func toDTO(from domain: Character) -> CharacterDTO {
        return CharacterDTO(
            avatar: domain.avatar,
            name: domain.name,
            maxHealth: domain.maxHealth,
            currentHealth: domain.currentHealth,
            dexterity: domain.dexterity,
            strength: domain.strength,
            gold: domain.gold,
            skipAttack: domain.skipAttack,
            currentWeapon: domain.currentWeapon.map(ItemMapper.toDTO),
            inventory: InventoryMapper.toDTO(from: domain.inventory),
            statusEffects: domain.statusEffects.map(StatusEffectMapper.toDTO)
        )
    }
    
    static func toDomain(from dto: CharacterDTO) -> Character {
        var character = Character(
            name: dto.name,
            maxHealth: dto.maxHealth,
            currentHealth: dto.currentHealth,
            dexterity: dto.dexterity,
            strength: dto.strength,
            gold: dto.gold
        )
        character.skipAttack = dto.skipAttack
        character.currentWeapon = dto.currentWeapon.map(ItemMapper.toDomain)
        character.inventory = InventoryMapper.toDomain(from: dto.inventory)
        character.statusEffects = dto.statusEffects.map(StatusEffectMapper.toDomain)
        return character
    }
}

class InventoryMapper {
    static func toDTO(from domain: Inventory) -> InventoryDTO {
        return InventoryDTO(items: domain.items.map(ItemMapper.toDTO))
    }
    
    static func toDomain(from dto: InventoryDTO) -> Inventory {
        return Inventory(items: dto.items.map(ItemMapper.toDomain))
    }
}

final class SpecialEffectMapper {
    static func toDTO(from domain: SpecialEffect) -> SpecialEffectDTO {
        switch domain {
        case .lifeDrain: return .lifeDrain
        case .invisibility: return .invisibility
        case .rest: return .rest
        case .sleep: return .sleep
        }
    }
    
    static func toDomain(from dto: SpecialEffectDTO) -> SpecialEffect {
        switch dto {
        case .lifeDrain: return .lifeDrain
        case .invisibility: return .invisibility
        case .rest: return .rest
        case .sleep: return .sleep
        }
    }
    static func effectsToDTO(from effects: [Effect]) -> [SpecialEffectDTO] {
        return effects.compactMap { effect in
            if effect is LifeDrainEffect { return .lifeDrain }
            if effect is InvisibilityEffect { return .invisibility }
            if effect is RestEffect { return .rest }
            if effect is SleepEffect { return .sleep }
            return nil
        }
    }
    static func effectsToDomain(from dtos: [SpecialEffectDTO]) -> [Effect] {
        return dtos.map { dto in
            switch dto {
            case .lifeDrain: return LifeDrainEffect()
            case .invisibility: return InvisibilityEffect()
            case .rest: return RestEffect()
            case .sleep: return SleepEffect()
            }
        }
    }
    
}


final class EnemyMapper {
    static func toDTO(from domain: Enemy) -> EnemyDTO {
        return EnemyDTO(
            type: toDTO(from: domain.type),
            avatar: domain.avatar,
            name: domain.name,
            maxHealth: domain.maxHealth,
            currentHealth: domain.currentHealth,
            dexterity: domain.dexterity,
            strength: domain.strength,
            gold: domain.gold,
            hostility: toDTO(from: domain.hostility),
            effects: domain.effects.compactMap(SpecialEffectDTO.fromEffect),
            statusEffects: domain.statusEffects.map(StatusEffectMapper.toDTO),
            lastPosition: domain.lastPosition.map(CoordinatesMapper.toDTO),
            evasionUsed: domain.evasionUsed,
            isInvisible: domain.isInvisible,
            isDisguised: domain.isDisguised
        )
    }
    
    static func toDomain(from dto: EnemyDTO) -> Enemy {
        return Enemy(
            type: toDomain(from: dto.type),
            avatar: dto.avatar,
            name: dto.name,
            maxHealth: dto.maxHealth,
            currentHealth: dto.currentHealth,
            dexterity: dto.dexterity,
            strength: dto.strength,
            gold: dto.gold,
            hostility: toDomain(from: dto.hostility),
            effects: dto.effects.map { $0.effect },
            statusEffects: dto.statusEffects.map(StatusEffectMapper.toDomain),
            lastPosition: dto.lastPosition.map(CoordinatesMapper.toDomain),
            evasionUsed: dto.evasionUsed,
            isDisguised: dto.isDisguised
        )
    }
    
    private static func toDTO(from domain: EnemyType) -> EnemyTypeDTO {
        switch domain {
        case .zombie: return .zombie
        case .vampire: return .vampire
        case .ghost: return .ghost
        case .ogre: return .ogre
        case .snakeMage: return .snakeMage
        case .mimic: return .mimic
        }
    }
    
    private static func toDomain(from dto: EnemyTypeDTO) -> EnemyType {
        switch dto {
        case .zombie: return .zombie
        case .vampire: return .vampire
        case .ghost: return .ghost
        case .ogre: return .ogre
        case .snakeMage: return .snakeMage
        case .mimic: return .mimic
        }
    }
    
    private static func toDTO(from domain: Hostility) -> HostilityDTO {
        switch domain {
        case .noagro: return .noagro
        case .passive: return .passive
        case .hostile: return .hostile
        case .aggressive: return .aggressive
        }
    }
    
    private static func toDomain(from dto: HostilityDTO) -> Hostility {
        switch dto {
        case .noagro: return .noagro
        case .passive: return .passive
        case .hostile: return .hostile
        case .aggressive: return .aggressive
        }
    }
}

final class StatusEffectMapper {
    static func toDTO(from domain: StatusEffect) -> StatusEffectDTO {
        switch domain {
        case .sleep(let duration):
            return .sleep(duration: duration)
        case .invisible(let duration):
            return .invisible(duration: duration)
        case .rest(let duration):
            return .rest(duration: duration)
        case .evasion(let duration):
            return .evasion(duration: duration)
        case .buffStrength(let amount, let duration):
            return .buffStrength(amount: amount, duration: duration)
        case .buffDexterity(let amount, let duration):
            return .buffDexterity(amount: amount, duration: duration)
        case .buffMaxHealth(let amount, let duration):
            return .buffMaxHealth(amount: amount, duration: duration)
        }
    }
    
    static func toDomain(from dto: StatusEffectDTO) -> StatusEffect {
        switch dto {
        case .sleep(let duration):
            return .sleep(duration: duration)
        case .invisible(let duration):
            return .invisible(duration: duration)
        case .rest(let duration):
            return .rest(duration: duration)
        case .evasion(let duration):
            return .evasion(duration: duration)
        case .buffStrength(let amount, let duration):
            return .buffStrength(amount: amount, duration: duration)
        case .buffDexterity(let amount, let duration):
            return .buffDexterity(amount: amount, duration: duration)
        case .buffMaxHealth(let amount, let duration):
            return .buffMaxHealth(amount: amount, duration: duration)
        }
    }
}


class PlacedMapper {
    static func toPlayerDTO(from domain: PlacedPlayer) -> PlacedPlayerDTO {
        return PlacedPlayerDTO(
            id: ActorIDMapper.toDTO(from: domain.id),
            position: CoordinatesMapper.toDTO(from: domain.position),
            model: CharacterMapper.toDTO(from: domain.model)
        )
    }
    
    static func toPlayerDomain(from dto: PlacedPlayerDTO) -> PlacedPlayer {
        return PlacedPlayer(
            position: CoordinatesMapper.toDomain(from: dto.position),
            model: CharacterMapper.toDomain(from: dto.model)
        )
    }
    
    static func toEnemyDTO(from domain: PlacedEnemy) -> PlacedEnemyDTO {
        return PlacedEnemyDTO(
            id: ActorIDMapper.toDTO(from: domain.id),
            position: CoordinatesMapper.toDTO(from: domain.position),
            model: EnemyMapper.toDTO(from: domain.model)
        )
    }
    
    static func toEnemyDomain(from dto: PlacedEnemyDTO) -> PlacedEnemy {
        return PlacedEnemy(
            position: CoordinatesMapper.toDomain(from: dto.position),
            model: EnemyMapper.toDomain(from: dto.model)
        )
    }
}

class DomainHUDMapper {
    static func toDTO(from domain: DomainHUD) -> DomainHUDDTO {
        return DomainHUDDTO(
            weaponName: domain.weaponName,
            gold: domain.gold,
            hp: domain.hp,
            maxHP: domain.maxHP,
            depth: domain.depth,
            inventorySummary: domain.inventorySummary
        )
    }
    
    static func toDomain(from dto: DomainHUDDTO) -> DomainHUD {
        return DomainHUD(
            weaponName: dto.weaponName,
            gold: dto.gold,
            hp: dto.hp,
            maxHP: dto.maxHP,
            depth: dto.depth,
            inventorySummary: dto.inventorySummary
        )
    }
}

class DomainSnapshotMapper {
    static func toDTO(from domain: DomainSnapshot) -> DomainSnapshotDTO {
        return DomainSnapshotDTO(
            canvasSize: SizeMapper.toDTO(from: domain.canvasSize),
            rooms: domain.rooms.map(RoomMapper.toDTO),
            corridors: domain.corridors.map(CorridorPathMapper.toDTO),
            worldItems: domain.worldItems.map(PlacedItemMapper.toDTO),
            player: PlacedMapper.toPlayerDTO(from: domain.player),
            enemies: domain.enemies.map(PlacedMapper.toEnemyDTO),
            hud: DomainHUDMapper.toDTO(from: domain.hud),
            explored: Array(domain.explored).map(CoordinatesMapper.toDTO)
        )
    }
    
    static func toDomain(from dto: DomainSnapshotDTO) -> DomainSnapshot {
        return DomainSnapshot(
            canvasSize: SizeMapper.toDomain(from: dto.canvasSize),
            rooms: dto.rooms.map(RoomMapper.toDomain),
            corridors: dto.corridors.map(CorridorPathMapper.toDomain),
            worldItems: dto.worldItems.map(PlacedItemMapper.toDomain),
            player: PlacedMapper.toPlayerDomain(from: dto.player),
            enemies: dto.enemies.map(PlacedMapper.toEnemyDomain),
            hud: DomainHUDMapper.toDomain(from: dto.hud),
            explored: Set(dto.explored.map(CoordinatesMapper.toDomain))
        )
    }
}


class ItemKindMapper {
    static func toDTO(from domain: ItemType) -> ItemKindCodable {
        switch domain {
        case .weapon: return .weapon
        case .food: return .food
        case .potion: return .potion
        case .scroll: return .scroll
        case .treasure: return .treasure
        case .key(let color):
            return .key(toDTO(from: color))
        case .exit: return .exit
        }
    }
    
    static func toDomain(from dto: ItemKindCodable) -> ItemType {
        switch dto {
        case .weapon: return .weapon
        case .food: return .food
        case .potion: return .potion
        case .scroll: return .scroll
        case .treasure: return .treasure
        case .key(let color): return .key(toDomain(from: color))
        case .exit: return .exit
        }
    }
    
    private static func toDTO(from domain: KeyColor) -> KeyColorCodable {
        switch domain {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        }
    }
    
    private static func toDomain(from dto: KeyColorCodable) -> KeyColor {
        switch dto {
        case .red: return .red
        case .blue: return .blue
        case .yellow: return .yellow
        }
    }
}
class ItemMapper {
    static func toDTO(from domain: Item) -> ItemCodable {
        return ItemCodable(name: domain.name, kind: ItemKindMapper.toDTO(from: domain.type))
    }
    
    static func toDomain(from dto: ItemCodable) -> Item {
        let kind = ItemKindMapper.toDomain(from: dto.kind)
        
        switch kind {
        case .food:
            return Item(
                type: .food,
                name: dto.name,
                healthBoost: 3
            )
        case .potion:
            return Item(
                type: .potion,
                name: dto.name,
                temporaryHealthBoost: 4
            )
        case .scroll:
            return Item(
                type: .scroll,
                name: dto.name,
                dexterityBoost: 2
            )
        case .treasure:
            return Item(
                type: .treasure,
                name: dto.name,
                value: 2...8
            )
        case .weapon:
            return Item(
                type: .weapon,
                name: dto.name,
                damageRange: 1...3
            )
        case .key(let color):
            return Item(
                type: .key(color),
                name: dto.name
            )
        case .exit:
            return Item(
                type: .exit,
                name: dto.name
            )
        }
    }
}

class PlacedItemMapper {
    static func toDTO(from domain: PlacedItem) -> PlacedItemCodable {
        return PlacedItemCodable(
            position: CoordinatesMapper.toDTO(from: domain.position),
            item: ItemMapper.toDTO(from: domain.item)
        )
    }
    
    static func toDomain(from dto: PlacedItemCodable) -> PlacedItem {
        return PlacedItem(
            position: CoordinatesMapper.toDomain(from: dto.position),
            item: ItemMapper.toDomain(from: dto.item)
        )
    }
}
