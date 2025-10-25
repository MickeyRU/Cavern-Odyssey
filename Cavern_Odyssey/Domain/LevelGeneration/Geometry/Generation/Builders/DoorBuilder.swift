import Foundation

enum DoorBuilder: PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan { apply(to: plan) }

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        var p = plan
        precondition(p.rooms.count == 9, "Ожидаем 3×3 комнаты")
        let grid = stride(from: 0, to: p.rooms.count, by: 3).map { Array(p.rooms[$0..<$0+3]) }
        let res = DoorFactory.addDoors(for: grid, edges: p.edges)
        p.rooms = res.grid.flatMap { $0 }
        p.doorLinks = res.links
        return p
    }
}
