import Foundation

enum GraphBuilder: PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan { apply(to: plan) }

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        var p = plan
        p.edges = GraphConnector.buildEdges(roomsFlat: p.rooms)
        return p
    }
}
