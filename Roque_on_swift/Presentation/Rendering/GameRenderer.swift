import Foundation
import Darwin.ncurses

/// Рендер окружения и акторов с учётом тумана.
enum GameRenderer {
    // Палитра
    enum ColorPair: Int16 {
        case wall = 1, door, floor, tunnel
        case player
        case zombie, vampire, ghost, ogre, snakeMage, mimic
        case item, hud
        case doorRed, doorBlue, doorYellow
        case keyRed, keyBlue, keyYellow
        case exit
        
    }
    
    // Глифы для тайлов
    enum Glyph {
        static let wallH   = "═"
        static let wallV   = "║"
        static let corner  = "╬"
        static let floor   = "·"
        static let door    = "¤"
        static let tunnel  = "░"
        static let key     = "k"
        static let chest   = "⊞"
        static let exit    = "⤴"
    }
    
    // Безопасная печать строки внутри границ
    private static func putUnicode(_ y: Int, _ x: Int, _ s: String, in bounds: Size, color: ColorPair? = nil) {
        guard x >= 0, y >= 0, x < bounds.width, y < bounds.height else { return }
        if let cp = color { attron(COLOR_PAIR(Int32(cp.rawValue))) }
        _ = s.withCString { mvaddstr(Int32(y), Int32(x), $0) }
        if let cp = color { attroff(COLOR_PAIR(Int32(cp.rawValue))) }
    }
    
    // MARK: - Environment helpers
    private static func wallsSet(for rooms: [RoomSnapshot]) -> Set<Coordinates> {
        var s = Set<Coordinates>()
        for r in rooms {
            let left   = r.origin.x
            let right  = r.origin.x + r.width  - 1
            let top    = r.origin.y
            let bottom = r.origin.y + r.height - 1
            
            for x in left...right {
                s.insert(.init(x: x, y: top))
                s.insert(.init(x: x, y: bottom))
            }
            for y in top...bottom {
                s.insert(.init(x: left,  y: y))
                s.insert(.init(x: right, y: y))
            }
        }
        return s
    }
    
    // MARK: - Environment (masked)
    /// Рисуем окружение по правилам тумана:
    /// - !seen: пусто
    /// - seen \ visible: только стены
    /// - visible: стены + пол + коридоры + двери
    private static func drawEnvironmentMasked(world: GameWorldSnapshot,
                                              fog: VisibilityMap,
                                              clear: Bool = true) {
        if clear { erase() }
        
        let walls = wallsSet(for: world.rooms)
        
        // 1) стены: если клетка ∈ (visible ∪ seen)
        let wallToDraw = walls.intersection(fog.visible.union(fog.seenByLevel))
        
        // аккуратно рисуем периметры комнат, проверяя на видимость стены
        for r in world.rooms {
            // вертикали
            for y in r.top...r.bottom {
                let L = Coordinates(x: r.left,  y: y)
                let R = Coordinates(x: r.right, y: y)
                if wallToDraw.contains(L) { putUnicode(y, r.left,  Glyph.wallV, in: world.canvasSize, color: .wall) }
                if wallToDraw.contains(R) { putUnicode(y, r.right, Glyph.wallV, in: world.canvasSize, color: .wall) }
            }
            // горизонты
            for x in r.left...r.right {
                let T = Coordinates(x: x, y: r.top)
                let B = Coordinates(x: x, y: r.bottom)
                if wallToDraw.contains(T) { putUnicode(r.top,    x, Glyph.wallH, in: world.canvasSize, color: .wall) }
                if wallToDraw.contains(B) { putUnicode(r.bottom, x, Glyph.wallH, in: world.canvasSize, color: .wall) }
            }
            // углы (если попадают в wallToDraw)
            for c in [Coordinates(x: r.left, y: r.top),
                      Coordinates(x: r.right, y: r.top),
                      Coordinates(x: r.left, y: r.bottom),
                      Coordinates(x: r.right, y: r.bottom)] where wallToDraw.contains(c) {
                putUnicode(c.y, c.x, Glyph.corner, in: world.canvasSize, color: .wall)
            }
        }
        
        // 2) пол комнат — ТОЛЬКО если клетка в visible
        for r in world.rooms where r.width >= 3 && r.height >= 3 {
            for y in (r.top+1)..<r.bottom {
                for x in (r.left+1)..<r.right {
                    let p = Coordinates(x: x, y: y)
                    if fog.visible.contains(p) {
                        putUnicode(y, x, Glyph.floor, in: world.canvasSize, color: .floor)
                    }
                }
            }
        }
        
        // 3) коридоры — ТОЛЬКО если клетка в visible
        for c in world.corridors {
            for p in c.tiles where fog.visible.contains(p) {
                putUnicode(p.y, p.x, Glyph.tunnel, in: world.canvasSize, color: .tunnel)
            }
        }
        
        // 4) двери — показываем только если видимы СЕЙЧАС
        for r in world.rooms {
            for d in r.doors where fog.visible.contains(d.position) {
                let glyph = Glyph.door
                let color: ColorPair
                switch d.kind {
                case .open:
                    color = .door
                case .locked(let keyColor):
                    switch keyColor {
                        case .red:    color = .keyRed
                        case .blue:   color = .keyBlue
                        case .yellow: color = .keyYellow
                    }
                }
                putUnicode(d.position.y, d.position.x, glyph, in: world.canvasSize, color: color)
            }
        }
        
        // 5) предметы на полу (ключи и пр.) — показываем только если видимы СЕЙЧАС
        for it in world.items where fog.visible.contains(it.position) {
            let (glyph, color): (String, ColorPair) = {
                switch it.item.kind {
                case .key(.red):    return (Glyph.key,  .keyRed)
                case .key(.blue):   return (Glyph.key,  .keyBlue)
                case .key(.yellow): return (Glyph.key,  .keyYellow)
                case .exit:         return (Glyph.exit, .exit)
                default:            return (Glyph.chest,  .item)
                }
            }()
            putUnicode(it.position.y, it.position.x, glyph, in: world.canvasSize, color: color)
        }
        
        refresh()
    }
    
    // MARK: - Actors
    private static func drawActors(_ actors: ActorsSnapshot, on canvas: Size, fog: VisibilityMap) {
        // --- Player ---
        let p = actors.player
        if fog.visible.contains(p.position) {
            attron(COLOR_PAIR(Int32(ColorPair.player.rawValue)))
            _ = "@".withCString {
                mvaddstr(Int32(p.position.y), Int32(p.position.x), $0)
            }
            attroff(COLOR_PAIR(Int32(ColorPair.player.rawValue)))
        }
        
        // --- Enemies ---
        for e in actors.enemies where fog.visible.contains(e.position) {
            // Определяем цвет по типу врага (по имени/символу/типу)
            
            if e.isInvisible {
                        continue
                    }
            
            let color: ColorPair
            let glyph: String
            
            switch e.name {
            case let n where n.contains("Зомби"):
                color = .zombie; glyph = "z"
            case let n where n.contains("Вампир"):
                color = .vampire; glyph = "v"
            case let n where n.contains("Привидение"):
                color = .ghost; glyph = "g"
            case let n where n.contains("Огр"):
                color = .ogre; glyph = "O"
            case let n where n.contains("Змей"):
                color = .snakeMage; glyph = "s"
//            case let n where n.contains("Мимик"):
//                color = .mimic; glyph = "m"
            case let n where n.contains("Мимик"):
                if e.isDisguised {
                    color = .item; glyph = "k"
                } else {
                    color = .mimic; glyph = "m"
                }
            default:
                color = .zombie; glyph = "?" // fallback
            }
            
            attron(COLOR_PAIR(Int32(color.rawValue)))
            _ = glyph.withCString {
                mvaddstr(Int32(e.position.y), Int32(e.position.x), $0)
            }
            attroff(COLOR_PAIR(Int32(color.rawValue)))
        }
    }
    
    // MARK: - HUD
    static func drawHUD(_ hud: HUDSnapshot, on canvas: Size, msg: String? = nil) {
        let y = canvas.height - 6
        attron(COLOR_PAIR(Int32(ColorPair.hud.rawValue)))
        for x in 0..<canvas.width { mvaddstr(Int32(y), Int32(x), " ") }
        let weapon = hud.weaponName ?? "—"
        let base = """
          Lvl: \(hud.lvl)  \
          Gold: \(hud.gold)  \
          HP: \(hud.hp)/\(hud.maxHp)  \
          STR: \(hud.str)  \
          DEX: \(hud.dex)  \
          Weapon: \(weapon)
          """
        let suffix = msg.map { "  |  \($0)" } ?? ""
        _ = (base + suffix).withCString { mvaddstr(Int32(y), 0, $0) }
        attroff(COLOR_PAIR(Int32(ColorPair.hud.rawValue)))
    }
    
    // MARK: - Frame
    static func drawFrame(world: GameWorldSnapshot,
                          actors: ActorsSnapshot,
                          fog: VisibilityMap,
                          clear: Bool = true) {
        
        drawEnvironmentMasked(world: world, fog: fog, clear: clear)
        drawActors(actors, on: world.canvasSize, fog: fog)
        
        ChatLogger.shared.drawChat(on: world.canvasSize)
        
        refresh()
    }
}
