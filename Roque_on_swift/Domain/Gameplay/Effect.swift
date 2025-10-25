import Foundation

enum EffectTiming {
    case beforeAttack
    case afterAttack
}

protocol Effect {
    var timing: EffectTiming { get }
    mutating func apply(to target: inout Character, from enemy: inout Enemy)
}

struct LifeDrainEffect: Effect {
    let timing: EffectTiming = .afterAttack

    mutating func apply(to target: inout Character, from enemy: inout Enemy) {
        if Int.random(in: 1...100) <= 30 {
            let damage = 2
            target.currentHealth -= damage
            enemy.currentHealth = min(enemy.maxHealth, enemy.currentHealth + damage)
            ChatLogger.shared.addMessage("🩸 \(enemy.name) похитил у вас \(damage) здоровья")
        }
    }
}

struct InvisibilityEffect: Effect {
    let timing: EffectTiming = .afterAttack

    mutating func apply(to target: inout Character, from enemy: inout Enemy) {
        if Int.random(in: 1...100) <= 15 {
            enemy.applyStatus(.invisible(duration: 1))
            ChatLogger.shared.addMessage("👻 \(enemy.name) стал невидим на 1 ход")
        }
    }
}

struct RestEffect: Effect {
    let timing: EffectTiming = .afterAttack

    mutating func apply(to target: inout Character, from enemy: inout Enemy) {
        enemy.applyStatus(.rest(duration: 1))
        ChatLogger.shared.addMessage("😮‍💨 \(enemy.name) устал и пропустит следующий ход")
    }
}

struct SleepEffect: Effect {
    let timing: EffectTiming = .afterAttack

    mutating func apply(to target: inout Character, from enemy: inout Enemy) {
        if Int.random(in: 1...100) <= 30 {
            target.applyStatus(.sleep(duration: 1))
            ChatLogger.shared.addMessage("💤 \(enemy.name) усыпил вас на 1 ход")
        } else {
            ChatLogger.shared.addMessage("🌀 \(enemy.name) пытался усыпить вас, но не получилось")
        }
    }
}

func effect(for special: SpecialEffect) -> Effect {
    switch special {
    case .lifeDrain: return LifeDrainEffect()
    case .invisibility: return InvisibilityEffect()
    case .rest: return RestEffect()
    case .sleep: return SleepEffect()
    }
}
