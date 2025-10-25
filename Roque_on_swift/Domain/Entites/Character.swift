import Foundation

struct Character: StatusApplicable {
    var avatar: String { "🧙‍♂️" }
    var name: String
    var maxHealth: Int
    var currentHealth: Int
    var dexterity: Int
    var strength: Int
    var currentWeapon: Item?
    var inventory: Inventory
    var gold: Int
    var statusEffects: [StatusEffect] = []
    var skipAttack: Bool = true

    init(
        name: String,
        maxHealth: Int = 30,
        currentHealth: Int = 30,
        dexterity: Int = 5,
        strength: Int = 5,
        gold: Int = 0
    ) {
        self.name = name
        self.maxHealth = maxHealth
        self.currentHealth = currentHealth
        self.dexterity = dexterity
        self.strength = strength
        self.currentWeapon = nil
        self.inventory = Inventory(items: [Item.apple])
        self.gold = gold
    }
    
}
