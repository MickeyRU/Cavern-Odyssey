import Foundation

protocol StatusApplicable {
    var statusEffects: [StatusEffect] { get set }

    mutating func applyStatus(_ effect: StatusEffect)
    mutating func updateStatusEffect()
    var canAct: Bool { get }
}

extension StatusApplicable {
    mutating func applyStatus(_ effect: StatusEffect) {
        let alreadyHasEffect: Bool = statusEffects.contains { existing in
            switch (existing, effect) {
            case (.sleep, .sleep),
                 (.rest, .rest),
                 (.evasion, .evasion),
                 (.invisible, .invisible):
                return true
            default:
                return false
            }
        }

        if !alreadyHasEffect {
            statusEffects.append(effect)
        }
    }

    mutating func updateStatusEffect() {
        statusEffects = statusEffects.compactMap { $0.nextDuration() }
    }

    // sleep и rest блокируют действие
    var canAct: Bool {
        for effect in statusEffects {
            switch effect {
            case .sleep, .rest:
                return false
            default: break
            }
        }
        return true
    }
}

// Применение эффектов от использования Items на Игроке
extension Character {
    mutating func updateStatusEffect() {
        var newEffects: [StatusEffect] = []

        for effect in statusEffects {
            if let next = effect.nextDuration() {
                newEffects.append(next)
            } else {
                // Эффект закончился — выполняем откат только для персонажа
                switch effect {
                case .buffStrength(let amount, _):
                    strength -= amount

                case .buffDexterity(let amount, _):
                    dexterity -= amount

                case .buffMaxHealth(let amount, _):
                    maxHealth -= amount
                    if currentHealth > maxHealth {
                        currentHealth = maxHealth
                    }

                default:
                    break
                }
            }
        }

        statusEffects = newEffects
    }
}
