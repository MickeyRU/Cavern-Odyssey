import Foundation

protocol LevelGenerator {
    func generate(canvas: Size, session: inout GameSession) -> LevelState
}

struct SimpleLevelGenerator: LevelGenerator {
    func generate(canvas: Size, session: inout GameSession) -> LevelState {
        var plan = LevelPlanBuilder(canvas: canvas).buildRooms()
        plan = GraphBuilder.apply(to: plan)
        plan = DoorBuilder.apply(to: plan)
        plan = CorridorBuilder.apply(to: plan)
        plan = ExitBuilder.apply(to: plan)
        plan = LockAndKeyBuilder.apply(to: plan)
        plan = PlayerBuilder.apply(to: plan, session: session)
        plan = EnemyBuilder.apply(to: plan, depth: session.depth)
        plan = ItemsBuilder.apply(to: plan, depth: session.depth)
        return LevelAssembler.assemble(plan: plan, depth: session.depth, playerModel: session.player)
    }
}
