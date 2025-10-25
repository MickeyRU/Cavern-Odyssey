import Foundation

enum DomainToDTOMapper {
    static func map(_ snap: DomainSnapshot) -> GameFrameDTO {
        let world = GameWorldSnapshot(
            canvasSize: snap.canvasSize,
            rooms: snap.rooms.map(mapRoom),
            corridors: snap.corridors,
            items: snap.worldItems.map(mapPlacedItem),
            explored: snap.explored)
        
        let playerDTO = PlayerSnapshot(
            id: snap.player.id,
            name: snap.player.model.name,
            avatar: snap.player.model.avatar,
            position: snap.player.position,
            inventory: mapInventory(snap.player.model.inventory,
                                    currentWeapon: snap.player.model.currentWeapon))
        
        let enemiesDTO = snap.enemies.map {
            EnemySnapshot(
                id: $0.id,
                name: $0.model.name,
                avatar: $0.model.avatar,
                position: $0.position,
                isInvisible: $0.model.isInvisible,
                isDisguised: $0.model.isDisguised
            )
        }
        
        let actors = ActorsSnapshot(player: playerDTO, enemies: enemiesDTO)
        
        let hud = HUDSnapshot(weaponName: snap.player.model.currentWeapon?.name,
                             gold: snap.player.model.gold,
                             hp: snap.player.model.currentHealth,
                             maxHp: snap.player.model.maxHealth,
                             lvl: snap.hud.depth,
                             dex: snap.player.model.dexterity,
                             str: snap.player.model.strength)
        
        return GameFrameDTO(world: world, actors: actors, hud: hud)
    }
    
    
    // MARK: - World / Rooms / Doors
    
    private static func mapRoom(_ r: Room) -> RoomSnapshot {
        RoomSnapshot(
            origin: r.origin,
            width: r.width,
            height: r.height,
            doors: r.doors.map(mapDoor)
        )
    }
    
    private static func mapDoor(_ d: Door) -> DoorSnapshot {
        DoorSnapshot(position: d.position, kind: mapDoorKind(d.kind))
    }
    
    private static func mapDoorKind(_ k: DoorKind) -> DoorKindDTO {
        switch k {
        case .open:
            return .open
        case .locked(let color):
            return .locked(mapKeyColor(color))
        }
    }
    
    private static func mapKeyColor(_ c: KeyColor) -> KeyColorDTO {
        switch c {
        case .red:    return .red
        case .blue:   return .blue
        case .yellow: return .yellow
        }
    }
    
    // MARK: - Items (на полу)
    
    private static func mapPlacedItem(_ it: PlacedItem) -> PlacedItemDTO {
        PlacedItemDTO(position: it.position, item: mapItem(it.item))
    }
    
    private static func mapItem(_ i: Item) -> ItemDTO {
        ItemDTO(name: i.name, kind: mapItemType(i.type))
    }
    
    private static func mapItemType(_ t: ItemType) -> ItemKindDTO {
        switch t {
        case .weapon:   return .weapon
        case .food:     return .food
        case .potion:   return .potion
        case .scroll:   return .scroll
        case .treasure: return .treasure
        case .key(let color):
            return .key(mapKeyColor(color))
        case .exit :    return .exit
        }
    }
    
    // MARK: - Inventory (у игрока)
    
    static func mapInventory(_ inv: Inventory, currentWeapon: Item?) -> InventorySnapshot {
        let weapons   = inv.items.filter { if case .weapon   = $0.type { return true } else { return false } }
        let foods     = inv.items.filter { if case .food     = $0.type { return true } else { return false } }
        let potions   = inv.items.filter { if case .potion   = $0.type { return true } else { return false } }
        let scrolls   = inv.items.filter { if case .scroll   = $0.type { return true } else { return false } }
        let treasures = inv.items.filter { if case .treasure = $0.type { return true } else { return false } }
                
        func toDTO(_ i: Item) -> ItemDTO { mapItem(i) }
        
        let equippedIdx: Int? = {
            guard let cur = currentWeapon, case .weapon = cur.type else { return nil }
            return weapons.firstIndex(where: { $0.name == cur.name })
        }()
        
        return InventorySnapshot(
            weapons: weapons.map(toDTO),
            foods: foods.map(toDTO),
            potions: potions.map(toDTO),
            scrolls: scrolls.map(toDTO),
            treasures: treasures.map(toDTO),
            equippedWeaponIndex: equippedIdx
        )
    }
}
