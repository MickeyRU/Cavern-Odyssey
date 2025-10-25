//
//  StatusEffect.swift
//  Roque_on_swift
//
//  Created by Ренат on 31.08.2025.
//

import Foundation

enum StatusEffect {
    case sleep(duration: Int)
    case invisible(duration: Int)
    case rest(duration: Int)
    case evasion(duration: Int)
    
    // для применения Items
    case buffStrength(amount: Int, duration: Int)
    case buffDexterity(amount: Int, duration: Int)
    case buffMaxHealth(amount: Int, duration: Int)
    
    func nextDuration() -> StatusEffect? {
        switch self {
        case .sleep(let t) where t > 0:
            return .sleep(duration: t - 1)
            
        case .invisible(let t) where t > 0:
            return .invisible(duration: t - 1)
            
        case .rest(let t) where t > 0:
            return .rest(duration: t - 1)
            
        case .evasion(let t) where t > 0:
            return .evasion(duration: t - 1)
            
            // временные баффы
        case .buffStrength(let a, let t) where t > 0:   return .buffStrength(amount: a, duration: t - 1)
        case .buffDexterity(let a, let t) where t > 0:  return .buffDexterity(amount: a, duration: t - 1)
        case .buffMaxHealth(let a, let t) where t > 0:  return .buffMaxHealth(amount: a, duration: t - 1)
            
        default:
            return nil
        }
    }
}
