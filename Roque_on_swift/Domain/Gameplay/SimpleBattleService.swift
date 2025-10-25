import Foundation

enum BattleResult {
    case heroWon
    case heroDied
    case enemyFled
}

protocol BattleService {
    func startBattle(hero: Character, enemy: Enemy) -> (result: BattleResult, updatedHero: Character, updatedEnemy: Enemy)
}

final class SimpleBattleService: BattleService {
    private let store: LevelStateStore?

    init(store: LevelStateStore? = nil) {
        self.store = store
    }

    func startBattle(hero: Character, enemy: Enemy) -> (result: BattleResult, updatedHero: Character, updatedEnemy: Enemy) {
        ChatLogger.shared.addMessage("⚔️ БИТВА: \(hero.name) ❤️ \(hero.currentHealth) vs \(enemy.name) 💚\(enemy.currentHealth)")
        ChatLogger.shared.addMessage("")

        var currentHero = hero
        var currentEnemy = enemy

        // 1️⃣ Ход героя
        if currentEnemy.type == .mimic {
            currentEnemy.isDisguised = false
            currentEnemy.hostility = .aggressive
        }
        
        if currentEnemy.type == .vampire, !currentEnemy.evasionUsed {
            // Первый удар по вампиру всегда мимо
            ChatLogger.shared.addMessage("\(currentEnemy.name) использовал evasion 💫 и увернулся от вашего удара")
            currentEnemy.evasionUsed = true
        } else if currentHero.canAct {
            let hitChance = max(10, 50 + (currentHero.dexterity - currentEnemy.dexterity) * 5)
            let roll = Int.random(in: 1...100)

            if roll <= hitChance {
                let weaponDamage = currentHero.currentWeapon?.damageRange?.randomElement() ?? 2
                let totalDamage = currentHero.strength + weaponDamage
                currentEnemy.currentHealth -= totalDamage
                ChatLogger.shared.addMessage("💥 Вы нанесли \(totalDamage) урона")
                RunRecord.addRecord.hitsDealt += 1
            } else {
                ChatLogger.shared.addMessage("❌ Вы промахнулись")
                RunRecord.addRecord.hitsTaken += 1
            }
        } else if !currentHero.canAct {
            ChatLogger.shared.addMessage("💤 Вы не можете атаковать (Сон)")
        }

        // Проверка смерти врага
        if currentEnemy.currentHealth <= 0 {
            ChatLogger.shared.addMessage("")
            ChatLogger.shared.addMessage("⚔️ Результат битвы: ✅ \(currentEnemy.name) повержен! Получено \(currentEnemy.gold) 🪙Gold Coin")

            currentHero.gold += currentEnemy.gold
            RunRecord.addRecord.treasures += currentEnemy.gold
            RunRecord.addRecord.enemiesDefeated += 1
            return (.heroWon, currentHero, currentEnemy)
        }

        // 2️⃣ Ход врага
        if currentEnemy.canAct {
            let hitChance = max(30, 50 + (currentEnemy.dexterity - currentHero.dexterity) * 5)
            let roll = Int.random(in: 1...100)

            if roll <= hitChance {
                let damage = max(2, currentEnemy.strength / 2)
                currentHero.currentHealth -= damage
                ChatLogger.shared.addMessage("💥 \(currentEnemy.name) наносит \(damage) урона")

                // Применяем эффекты после успешной атаки
                applyEffects(timing: .afterAttack, hero: &currentHero, enemy: &currentEnemy)
            } else {
                ChatLogger.shared.addMessage("❌ \(currentEnemy.name) промахнулся")
                // Эффекты применяются даже при промахе
                applyEffects(timing: .afterAttack, hero: &currentHero, enemy: &currentEnemy)
            }
        } else {
            ChatLogger.shared.addMessage("😮‍💨 \(currentEnemy.name) не может атаковать (усталость)")
        }
    
        // Проверка смерти героя
        if currentHero.currentHealth <= 0 {
            return (.heroDied, currentHero, currentEnemy)
        }

        // 3️⃣ Завершение хода
        ChatLogger.shared.addMessage("\n⚔️ Результат битвы: \(currentHero.name) ❤️ \(currentHero.currentHealth) vs \(currentEnemy.name) 💚 \(currentEnemy.currentHealth)")
        
        // Сохраняем состояние игры после битвы
        if let store = store {
            var state = store.state
            state.player.model = currentHero
            store.state = state
        }

        return (.enemyFled, currentHero, currentEnemy)
    }

    private func applyEffects(timing: EffectTiming, hero: inout Character, enemy: inout Enemy) {
        for i in enemy.effects.indices {
            var effect = enemy.effects[i]
            if effect.timing == timing {
                effect.apply(to: &hero, from: &enemy)
                enemy.effects[i] = effect
            }
        }
    }
}
