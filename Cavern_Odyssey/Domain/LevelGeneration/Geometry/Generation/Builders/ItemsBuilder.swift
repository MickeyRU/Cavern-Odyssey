import Foundation

enum ItemsBuilder: PlanStep {

    // MARK: - Helpers (инвентарь и типы)

    private struct InventorySummary {
        var foodCount: Int = 0
        var healingPotential: Int = 0
        var scrollsTotal: Int = 0
        var scrollsByKind: [String: Int] = [:]
        var weaponNames: Set<String> = []
    }

    private static func healingValue(for item: Item) -> Int {
        let name = item.name
        if name == Item.apple.name { return 5 }
        if name == Item.bread.name { return 12 }
        if name == Item.healingPotion.name { return 25 }
        return 0
    }

    private static func isFood(_ item: Item) -> Bool {
        if case .food = item.type { return true }
        return item.name == Item.healingPotion.name
    }

    private static func isScroll(_ item: Item) -> Bool {
        if case .scroll = item.type { return true }
        return false
    }

    private static func isWeapon(_ item: Item) -> Bool {
        if case .weapon = item.type { return true }
        return false
    }

    private static func summarizeInventory(_ items: [Item]) -> InventorySummary {
        var s = InventorySummary()
        for it in items {
            if isFood(it) {
                s.foodCount += 1
                s.healingPotential += healingValue(for: it)
            } else if isScroll(it) {
                s.scrollsTotal += 1
                s.scrollsByKind[it.name, default: 0] += 1
            } else if isWeapon(it) {
                s.weaponNames.insert(it.name)
            }
        }
        return s
    }

    // MARK: - Entry

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        return apply(to: plan, depth: 1)
    }

    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan {
        var p = plan
        guard !p.rooms.isEmpty, let player = p.player?.model else { return p }

        var rng = SystemRandomNumberGenerator()
        var items: [PlacedItem] = []

        let inventory = player.inventory.items
        let inv = summarizeInventory(inventory)

        // «Эффективное» здоровье: часть лечилок считаем как потенциально используемую
        let useFactor: Double = 0.6
        let effHP = min(
            1.0,
            (Double(player.currentHealth) + useFactor * Double(inv.healingPotential)) / Double(player.maxHealth)
        )

        var levelScrolls = 0

        // Пулы предметов
        let scrolls: [Item] = [.scrollOfHealth, .scrollOfDexterity, .scrollOfStrength]
        let food:    [Item] = [.apple, .bread, .healingPotion]
        let weapons: [Item] = [.dagger, .sword, .battleAxe]

        let scrollOfStrengthName = Item.scrollOfStrength.name

        // какие оружия уже есть у игрока
        let inventoryWeapons = inventory.filter { if case .weapon = $0.type { return true } else { return false } }
        let existingWeaponNames = Set(inventoryWeapons.map { $0.name })
        let availableWeapons = weapons.filter { !existingWeaponNames.contains($0.name) }

        // Количество предметов
        let minItems = min(2 + depth / 2, 5)
        let maxItems = min(p.rooms.count * 3 / 2, p.rooms.count * 2)
        let count = Int.random(in: minItems...maxItems, using: &rng)

        // Комнаты для размещения (кроме старта/выхода)
        var eligibleRooms = p.rooms.indices.filter { $0 != p.startIndex && $0 != p.exitIndex }
        eligibleRooms.shuffle(using: &rng)

        // ограничения
        var weaponGenerated = false
        let minFoodPerLevel = 1

        for i in 0..<count {
            if eligibleRooms.isEmpty { break }
            let roomIndex = eligibleRooms.removeFirst()
            guard let pos = RoomPlacementService.randomFreeFloor(in: p, roomIndex: roomIndex, rng: &rng) else { continue }

            // базовые веса
            var wFood:   Double = 0.30
            var wScroll: Double = 0.25
            var wWeapon: Double = 0.20
            let wOther:  Double = 0.25

            // --- контекстные модификаторы ---

            // ЕДА: если эффективный HP низкий — сильно повышаем; если высокий и еды много — снижаем
            if effHP < 0.5 { wFood += 0.30 }
            if effHP < 0.3 { wFood += 0.20 }
            if effHP > 0.8 && inv.foodCount >= 3 { wFood -= 0.20 }

            // Немного гарантии ранней еды
            if i < minFoodPerLevel { wFood += 0.20 }

            // СВИТКИ: урезаем, если их уже много на уровне или копятся непрочитанные
            if levelScrolls >= 2 { wScroll -= 0.15 }
            if inv.scrollsTotal >= 3 { wScroll -= 0.15 }

            // ОРУЖИЕ: одно за уровень; если у игрока уже 2+ разных — слегка режем шанс
            if weaponGenerated || availableWeapons.isEmpty { wWeapon = 0.0 }
            if inv.weaponNames.count >= 2 { wWeapon -= 0.05 }

            // Синергия: если есть свиток силы — чуть поднимаем шанс оружия, свитки уменьшаем
            if (inv.scrollsByKind[scrollOfStrengthName] ?? 0) > 0 {
                wWeapon += 0.05
                wScroll -= 0.05
            }

            // нормализация
            let wf = max(wFood, 0), ws = max(wScroll, 0), ww = max(wWeapon, 0), wo = max(wOther, 0)
            let total = wf + ws + ww + wo
            if total == 0 { continue }

            func pick(_ r: Double) -> Item {
                var t = r * total
                if t < wf, let it = food.randomElement(using: &rng) { return it }
                t -= wf
                if t < ws, let it = scrolls.randomElement(using: &rng) { return it }
                t -= ws
                if t < ww, !availableWeapons.isEmpty { return availableWeapons.randomElement(using: &rng)! }
                // ФОЛБЭК — еда, чтобы не было «пустых» выпадений
                return food.randomElement(using: &rng)!
            }

            let r = Double.random(in: 0..<1, using: &rng)
            let item = pick(r)

            // учёт per-level
            if isScroll(item) { levelScrolls += 1 }
            if isWeapon(item) { weaponGenerated = true }

            items.append(PlacedItem(position: pos, item: item))
        }

        p.items.append(contentsOf: items)
        return p
    }
}
