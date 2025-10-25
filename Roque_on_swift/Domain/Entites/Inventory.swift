import Foundation

struct Inventory {
    var items: [Item] = []
    
    mutating func add(_ item: Item) {
        items.append(item)
    }
    
    mutating func remove(_ item: Item) {
  
    }
    
    func listItems() -> String {
        if items.isEmpty {
            return "Инвентарь пуст"
        }
        return items.map { $0.name }.joined(separator: ", ")
    }  
}

extension Inventory {
    func containsKey(_ color: KeyColor) -> Bool {
        items.contains {
            if case let .key(c) = $0.type { return c == color }
            return false
        }
    }
}
