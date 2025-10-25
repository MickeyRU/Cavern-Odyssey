import Foundation

enum ItemEffectApplier {
    /// Возвращает сообщения для ChatLogger
    static func apply(_ item: Item, to c: inout Character, defaultDuration: Int = 12) -> [String] {
        var msgs: [String] = []

        switch item.type {
        case .food:
            if let heal = item.healthBoost {
                let before = c.currentHealth
                c.currentHealth = min(c.maxHealth, c.currentHealth + heal)
                let healed = c.currentHealth - before
                msgs.append("🍽️ \(item.name): восстановлено \(healed) HP")
            }

        case .scroll:
            if let mh = item.maxHealthBoost {
                c.maxHealth += mh
                c.currentHealth += mh
                msgs.append("📜 \(item.name): maxHP +\(mh)")
            }
            if let str = item.strengthBoost {
                c.strength += str
                msgs.append("📜 \(item.name): STR +\(str)")
            }
            if let dex = item.dexterityBoost {
                c.dexterity += dex
                msgs.append("📜 \(item.name): DEX +\(dex)")
            }

        case .potion:
            // Временные эффекты через статус
            if let tmp = item.temporaryHealthBoost {
                // немедленно поднимаем потолок и текущие HP
                c.maxHealth += tmp
                c.currentHealth += tmp
                c.applyStatus(.buffMaxHealth(amount: tmp, duration: defaultDuration))
                msgs.append("🧪 \(item.name): временно +\(tmp) maxHP на \(defaultDuration) ход(ов)")
            }
            if let str = item.strengthBoost {
                c.strength += str
                c.applyStatus(.buffStrength(amount: str, duration: defaultDuration))
                msgs.append("🧪 \(item.name): временно STR +\(str) на \(defaultDuration) ход(ов)")
            }
            if let dex = item.dexterityBoost {
                c.dexterity += dex
                c.applyStatus(.buffDexterity(amount: dex, duration: defaultDuration))
                msgs.append("🧪 \(item.name): временно DEX +\(dex) на \(defaultDuration) ход(ов)")
            }

        case .weapon, .treasure, .key, .exit:
            msgs.append("❌ \(item.name) нельзя использовать напрямую.")
        }

        return msgs
    }
}


