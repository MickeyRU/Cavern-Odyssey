import Foundation

enum LockAndKeyBuilder: PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan { apply(to: plan) }

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        var p = plan
        guard let exit = p.exitIndex else { return p }

        let result = LockAndKeyGenerator.generate(
            rooms: p.rooms,
            edges: p.edges,
            doorLinks: p.doorLinks,
            startIndex: p.startIndex,
            exitIndex: exit
        )
        p.rooms = result.rooms
        p.items.append(contentsOf: result.items)
        return p
    }
}
