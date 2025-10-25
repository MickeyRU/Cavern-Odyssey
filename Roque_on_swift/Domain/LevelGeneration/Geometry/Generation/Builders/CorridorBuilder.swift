import Foundation

enum CorridorBuilder: PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan { apply(to: plan) }

    static func apply(to plan: LevelGenerationPlan) -> LevelGenerationPlan {
        var p = plan
        var corridors: [CorridorPath] = []

        let allDoors = Set(p.rooms.flatMap { $0.doors.map(\.position) })
        var blocked = CorridorGenerator.buildBlocked(rooms: p.rooms, corridors: [], except: allDoors)

        for link in p.doorLinks {
            let path = CorridorGenerator.connect(
                doorA: link.from,
                doorB: link.to,
                worldBounds: p.canvasSize,
                blocked: &blocked
            )
            if !path.tiles.isEmpty {
                corridors.append(path)
                for t in path.tiles { blocked.insert(t) }
            }
        }

        p.corridors = corridors
        return p
    }
}
