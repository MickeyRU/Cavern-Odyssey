import Foundation

enum ItemType: Equatable {
    case food
    case potion
    case scroll
    case weapon
    case treasure
    case key(KeyColor)
    case exit
}

enum KeyColor { case red, blue, yellow }


struct Item {
    let type: ItemType
    var name: String
    
    var healthBoost: Int?
    var temporaryHealthBoost: Int?
    var maxHealthBoost: Int?
    var dexterityBoost: Int?
    var strengthBoost: Int?
    var value: ClosedRange<Int>?
    var damageRange: ClosedRange<Int>?
}

extension Item {
    static let apple = Item(
        type: .food,
        name: "🍎Apple",
        healthBoost: 5
    )
    
    static let bread = Item(
        type: .food,
        name: "🍞Bread",
        healthBoost: 10
    )
    
    static let healingPotion = Item(
        type: .potion,
        name: "🧪Healing Potion",
        temporaryHealthBoost: 15
    )
    
    static let scrollOfHealth = Item(
        type: .scroll,
        name: "📜Scroll Of Health",
        maxHealthBoost: 5
        
    )
    
    static let scrollOfDexterity = Item(
        type: .scroll,
        name: "📜Scroll Of Dexterity",
        dexterityBoost: 2
    )
    
    static let scrollOfStrength = Item(
        type: .scroll,
        name: "📜Scroll Of Strenght",
        strengthBoost: 2
    )
    
    static let dagger = Item(
        type: .weapon,
        name: "🔪Dagger",
        dexterityBoost: 1,
        strengthBoost: 1,
        damageRange: 1...4
    )
    
    static let sword = Item(
        type: .weapon,
        name: "🗡️Sword",
        strengthBoost: 2,
        damageRange: 2...6
    )
    
    static let battleAxe = Item(
        type: .weapon,
        name: "🪓Battle Axe",
        dexterityBoost: -1,
        strengthBoost: 2,
        damageRange: 3...8
    )
    
    static let gold = Item(
        type: .treasure,
        name: "🪙Gold Coin",
        value: 10...50
    )
    
    static let diamond = Item(
        type: .treasure,
        name: "💎Diamond",
        value: 100...100
    )
}

extension ItemType {
    var isExit: Bool {
        if case .exit = self { return true } else { return false }
    }
    var isPickable: Bool { !isExit }
}
