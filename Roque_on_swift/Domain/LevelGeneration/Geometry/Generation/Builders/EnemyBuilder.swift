import Foundation

enum EnemyBuilder: PlanStep {
        static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan {
        var p = plan
        guard !p.rooms.isEmpty else { return p }
        
        // 1) Собираем комнаты с ключами
        let keyRooms = roomsWithKeys(items: p.items, rooms: p.rooms)
        
        // 2) Базовый спавн: во всех keyRooms, кроме стартовой и комнаты с выходом
        var rng = SystemRandomNumberGenerator()
        var enemies: [PlacedEnemy] = []
        
        for rIdx in keyRooms {
            if rIdx == p.startIndex { continue }
            if let ex = p.exitIndex, rIdx == ex { continue }
            
            if let pos = RoomPlacementService.randomFreeFloor(in: p, roomIndex: rIdx, rng: &rng) {
                enemies.append(PlacedEnemy(position: pos, model: pickEnemy(for: depth, rng: &rng)))
            }
        }
        
        // Обновим план, чтобы последующие спавны знали о занятости
        p.enemies = enemies
        
        // 3) Дополнительные спавны по шансу, растущему с уровнем
        //    — сначала в тех же keyRooms, затем — в остальных комнатах (кроме старта/выхода)
        let extraChance = min(0.15 + 0.07 * Double(max(0, depth - 1)), 0.70) // 15% → 70%
        let extraPerKeyRoom = 1 + (depth >= 6 ? 1 : 0)                        // после 6 уровня иногда по 2
        
        // 3a) дополнительные монстры в keyRooms
        for rIdx in keyRooms {
            if rIdx == p.startIndex || rIdx == p.exitIndex { continue }
            for _ in 0..<extraPerKeyRoom {
                if roll(extraChance, &rng),
                   let pos = RoomPlacementService.randomFreeFloor(in: p, roomIndex: rIdx, rng: &rng) {
                    let m = pickEnemy(for: depth, rng: &rng)
                    let e = PlacedEnemy(position: pos, model: m)
                    p.enemies.append(e)
                }
            }
        }
        
        // 3b) шанс на спавн в прочих комнатах (кроме старта/выхода)
        let otherRooms = p.rooms.indices.filter { i in
            i != p.startIndex && i != p.exitIndex && !keyRooms.contains(i)
        }
        for rIdx in otherRooms {
            // Немного ниже шанс, чтобы карта не переполнялась
            if roll(extraChance * 0.6, &rng),
               let pos = RoomPlacementService.randomFreeFloor(in: p, roomIndex: rIdx, rng: &rng) {
                let m = pickEnemy(for: depth, rng: &rng)
                p.enemies.append(PlacedEnemy(position: pos, model: m))
            }
        }
        
        // 4) Страховка: если врагов всё ещё мало — досыпаем в случайные комнаты
              ensureMinimumEnemies(&p, depth: depth, rng: &rng)
        return p
    }
    
    // MARK: - Safety pass
    
    /// Обеспечивает минимум врагов на уровне, чтобы не было «пустых» карт,
    /// например когда ключи лежат в стартовой.
    private static func ensureMinimumEnemies<R: RandomNumberGenerator>(
        _ plan: inout LevelGenerationPlan,
        depth: Int,
        rng: inout R
    ) {
        // целевой минимум: растёт с уровнем, но ограничен количеством комнат
        let eligibleRooms = plan.rooms.indices.filter { i in
            i != plan.startIndex && i != plan.exitIndex
        }
        guard !eligibleRooms.isEmpty else { return }
        
        // Примерная формула: минимум = 2 + depth/2, но не больше чем (комнат-2)*2
        let hardCap = max(1, eligibleRooms.count * 2)
        let target = min(max(2 + depth / 2, 3), hardCap)
        
        // Если уже достаточно — выходим
        if plan.enemies.count >= target { return }
        
        // Пытаемся добавить недостающее количество, выбирая случайные комнаты
        var roomBag = eligibleRooms
        roomBag.shuffle(using: &rng)
        
        var attempts = 0
        let need = target - plan.enemies.count
        var added = 0
        
        while added < need && attempts < need * 8 { // анти-бесконечный цикл
            attempts += 1
            if roomBag.isEmpty {
                roomBag = eligibleRooms
                roomBag.shuffle(using: &rng)
            }
            let rIdx = roomBag.removeFirst()
            if let pos = RoomPlacementService.randomFreeFloor(in: plan, roomIndex: rIdx, rng: &rng) {
                let m = pickEnemy(for: depth, rng: &rng)
                plan.enemies.append(PlacedEnemy(position: pos, model: m))
                added += 1
            }
        }
    }
    
    
    // MARK: - Helpers
    
    /// Комнаты, в которых лежат ключи (.key(_))
    private static func roomsWithKeys(items: [PlacedItem], rooms: [Room]) -> Set<Int> {
        var result = Set<Int>()
        for it in items {
            guard case .key = it.item.type else { continue }
            if let idx = roomIndex(of: it.position, in: rooms) { result.insert(idx) }
        }
        return result
    }
    
    /// Индекс комнаты по глобальной координате пола
    private static func roomIndex(of p: Coordinates, in rooms: [Room]) -> Int? {
        for (i, r) in rooms.enumerated() {
            if p.x > r.left && p.x < r.right && p.y > r.top && p.y < r.bottom { return i }
        }
        return nil
    }
    
    /// Бросок вероятности
    private static func roll(_ probability: Double, _ rng: inout some RandomNumberGenerator) -> Bool {
        let v = Double.random(in: 0..<1, using: &rng)
        return v < probability
    }
    
    /// Выбор модели врага по уровню: от простых к сложным, с весами
    private static func pickEnemy<R: RandomNumberGenerator>(for depth: Int,
                                                            rng: inout R) -> Enemy {
        let table: [(Enemy, Double)] = [
            (.zombie,  max(0.55 - 0.03*Double(depth-1), 0.20)),
            (.ghost,   min(0.20 + 0.02*Double(depth-1), 0.35)),
            (.vampire, min(0.15 + 0.03*Double(depth-1), 0.30)),
            (.ogre,    min(0.10 + 0.03*Double(depth-1), 0.25)),
            (.snakeMage, min(0.10 + 0.03*Double(depth-1), 0.25)),
            (.mimic, min(0.10 + 0.03*Double(depth-1), 0.25))
        ]
        
        let sum = table.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<sum, using: &rng)
        for (enemy, w) in table {
            if r < w { return enemy }
            r -= w
        }
        return .zombie
    }
}
