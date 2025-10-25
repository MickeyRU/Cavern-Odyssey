import Foundation

final class PlayerActionInteractor: PlayerActionUseCase {
    private let store: LevelStateStore
    private let movement: MovementService
    
    init(store: LevelStateStore, movement: MovementService = MovementService()) {
        self.store = store
        self.movement = movement
    }
    
    func execute(_ action: PlayerAction) -> PlayerActionOutcome {
        var state = store.state
        
        // 1) Пытаемся обработать предметы
        if let outcome = handleItemAction(action, state: &state) {
            return finish(outcome, in: &state)
        }
        // 2) Иначе — движение
        return handleMovementAction(action, state: &state)
    }
}

// MARK: - Item actions
private extension PlayerActionInteractor {
    /// Возвращает Outcome, если действие было обработано; иначе nil.
    func handleItemAction(_ action: PlayerAction, state: inout LevelState) -> PlayerActionOutcome? {
        switch action {
        case .equipWeapon(let maybeIndex):
            return equipWeapon(maybeIndex, state: &state)
        case .eatFood(let idx):
            return eatFood(idx, state: &state)
        case .drinkPotion(let idx):
            return drinkPotion(idx, state: &state)
        case .readScroll(let idx):
            return readScroll(idx, state: &state)
        default:
            return nil
        }
    }
    
    func equipWeapon(_ index: Int?, state: inout LevelState) -> PlayerActionOutcome {
        // Сначала снимаем бонусы текущего оружия
        if let currentWeapon = state.player.model.currentWeapon {
            let removedStrength = currentWeapon.strengthBoost ?? 0
            let removedDexterity = currentWeapon.dexterityBoost ?? 0
            
            state.player.model.strength -= removedStrength
            state.player.model.dexterity -= removedDexterity
            
            // Сохраняем информацию о снятых статах для сообщения
            let removedStats = (strength: removedStrength, dexterity: removedDexterity)
            
            state.player.model.currentWeapon = nil
            ChatLogger.shared.clearChat()
            ChatLogger.shared.addMessage("⚔️ Оружие убрано")
            
            // Показываем какие статы убрались
            if removedStats.strength > 0 {
                ChatLogger.shared.addMessage("💪 Сила -\(removedStats.strength)")
            }
            if removedStats.dexterity != 0 {
                let symbol = removedStats.dexterity > 0 ? "-" : "+"
                let absValue = abs(removedStats.dexterity)
                ChatLogger.shared.addMessage("🎯 Ловкость \(symbol)\(absValue)")
            }
            
            if index == nil {
                return .moved
            }
        }
        
        if let idx = index {
            if let weapon = peekNth(of: .weapon, index: idx, in: state.player.model.inventory) {
                state.player.model.currentWeapon = weapon
                // Применяем бонусы нового оружия
                state.player.model.strength += (weapon.strengthBoost ?? 0)
                state.player.model.dexterity += (weapon.dexterityBoost ?? 0)
                
                ChatLogger.shared.clearChat()
                ChatLogger.shared.addMessage("⚔️ Экипировано: \(weapon.name)")
                if let str = weapon.strengthBoost, str > 0 {
                    ChatLogger.shared.addMessage("💪 Урон +\(str)")
                }
                if let dex = weapon.dexterityBoost, dex != 0 {
                    let symbol = dex > 0 ? "+" : ""
                    ChatLogger.shared.addMessage("🎯 Ловкость \(symbol)\(dex)")
                }
                
                return .moved
            } else {
                ChatLogger.shared.addMessage("❌ Неверный индекс оружия")
                return .moved
            }
        } else {
            // Если оружия и так не было экипировано
            if state.player.model.currentWeapon == nil {
                ChatLogger.shared.addMessage("⚔️ Оружие убрано")
                ChatLogger.shared.addMessage("ℹ️ Не было экипированного оружия")
            }
            return .moved
        }
    }
    
    func eatFood(_ filteredIndex: Int, state: inout LevelState) -> PlayerActionOutcome {
        guard let item = popNth(of: .food, index: filteredIndex, from: &state.player.model.inventory) else {
            ChatLogger.shared.addMessage("❌ Неверный индекс еды")
            return .blockedTerrain
        }
        let heal = item.healthBoost ?? 0
        let before = state.player.model.currentHealth
        state.player.model.currentHealth = min(state.player.model.maxHealth,
                                               state.player.model.currentHealth + heal)
        let healed = state.player.model.currentHealth - before
        ChatLogger.shared.addMessage("🍽️ \(item.name): восстановлено \(healed) HP")
        RunRecord.addRecord.foodEaten += 1
        return .moved
    }
    
    func drinkPotion(_ filteredIndex: Int, state: inout LevelState) -> PlayerActionOutcome {
        guard let item = popNth(of: .potion, index: filteredIndex, from: &state.player.model.inventory) else {
            ChatLogger.shared.addMessage("❌ Неверный индекс зелья")
            return .blockedTerrain
        }
        // Временные баффы (12 ходов) + немедленное применение
        if let tmp = item.temporaryHealthBoost {
            state.player.model.maxHealth += tmp
            state.player.model.currentHealth += tmp
            state.player.model.applyStatus(.buffMaxHealth(amount: tmp, duration: 12))
            ChatLogger.shared.addMessage("🧪 \(item.name): временно +\(tmp) maxHP (12 ходов)")
        }
        if let str = item.strengthBoost {
            state.player.model.strength += str
            state.player.model.applyStatus(.buffStrength(amount: str, duration: 12))
            ChatLogger.shared.addMessage("🧪 \(item.name): временно STR +\(str) (12 ходов)")
        }
        if let dex = item.dexterityBoost {
            state.player.model.dexterity += dex
            state.player.model.applyStatus(.buffDexterity(amount: dex, duration: 12))
            ChatLogger.shared.addMessage("🧪 \(item.name): временно DEX +\(dex) (12 ходов)")
        }
        RunRecord.addRecord.potionsDrunk += 1
        return .moved
    }
    
    func readScroll(_ filteredIndex: Int, state: inout LevelState) -> PlayerActionOutcome {
        guard let item = popNth(of: .scroll, index: filteredIndex, from: &state.player.model.inventory) else {
            ChatLogger.shared.addMessage("❌ Неверный индекс свитка")
            return .blockedTerrain
        }
        if let mh = item.maxHealthBoost {
            state.player.model.maxHealth += mh
            state.player.model.currentHealth += mh
            ChatLogger.shared.addMessage("📜 \(item.name): maxHP +\(mh)")
        }
        if let str = item.strengthBoost {
            state.player.model.strength += str
            ChatLogger.shared.addMessage("📜 \(item.name): STR +\(str)")
        }
        if let dex = item.dexterityBoost {
            state.player.model.dexterity += dex
            ChatLogger.shared.addMessage("📜 \(item.name): DEX +\(dex)")
        }
        RunRecord.addRecord.scrollsRead += 1
        return .moved
    }
}

// MARK: - Movement
private extension PlayerActionInteractor {
    func handleMovementAction(_ action: PlayerAction, state: inout LevelState) -> PlayerActionOutcome {
        let delta: (dx: Int, dy: Int)
        switch action {
        case .moveUp:    delta = (0,-1)
        case .moveDown:  delta = (0, 1)
        case .moveLeft:  delta = (-1,0)
        case .moveRight: delta = (1, 0)
        default:
            return .blockedTerrain
        }
        
        let cur = state.player.position
        let next = Coordinates(x: cur.x + delta.dx, y: cur.y + delta.dy)
        
        // террейн
        guard movement.isWalkableTerrain(next, in: state) else {
            return finish(.blockedTerrain, in: &state)
        }
        // актор
        if let (target, enemyModel) = movement.enemy(at: next, in: state) {
            return .engage(target.id, enemyModel)
        }
        // двигаем
        state.player.position = next
        
        // лут/выход
        if let outcome = pickupItems(at: next, state: &state) {
            return finish(outcome, in: &state)
        }
        
        return finish(.moved, in: &state)
    }
}

// MARK: - Pickup & Finish
private extension PlayerActionInteractor {
    /// Собирает предметы на клетке, возвращает Outcome если встретили выход.
    func pickupItems(at pos: Coordinates, state: inout LevelState) -> PlayerActionOutcome? {
        var picked: [PlacedItem] = []
        var touchedExit = false
        
        state.worldItems.removeAll { pi in
            guard pi.position == pos else { return false }
            if pi.item.type.isExit {
                touchedExit = true
                return false
            } else {
                picked.append(pi)
                return true
            }
        }
        
        if touchedExit { return .reachedExit }
        
        guard let pi = picked.first else { return nil }
        
        switch pi.item.type {
        case .treasure:
            let amount = pi.item.value?.lowerBound ?? 0
            state.player.model.gold += amount
            ChatLogger.shared.addMessage("🎒 Вы нашли \(pi.item.name)")
            RunRecord.addRecord.treasures += amount

        default:
            state.player.model.inventory.items.append(pi.item)
            ChatLogger.shared.addMessage("🎒 Вы подобрали: \(pi.item.name)")
        }
        
        return nil
    }
    
    /// Единая точка сохранения state и возврата результата
    func finish(_ outcome: PlayerActionOutcome, in state: inout LevelState) -> PlayerActionOutcome {
        store.state = state
        return outcome
    }
}

// MARK: - Inventory helpers (type-indexed access)
private extension PlayerActionInteractor {
    func peekNth(of type: ItemType, index n: Int, in inv: Inventory) -> Item? {
        var k = -1
        for it in inv.items where matchesType(it.type, type) {
            k += 1
            if k == n { return it }
        }
        return nil
    }
    
    func popNth(of type: ItemType, index n: Int, from inv: inout Inventory) -> Item? {
        var k = -1
        for i in inv.items.indices {
            if matchesType(inv.items[i].type, type) {
                k += 1
                if k == n { return inv.items.remove(at: i) }
            }
        }
        return nil
    }
    
    func matchesType(_ lhs: ItemType, _ rhs: ItemType) -> Bool {
        switch (lhs, rhs) {
        case (.food, .food), (.potion, .potion), (.scroll, .scroll),
            (.weapon, .weapon), (.treasure, .treasure), (.exit, .exit):
            return true
        case let (.key(a), .key(b)):
            return a == b
        default:
            return false
        }
    }
}
