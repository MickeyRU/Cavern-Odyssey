import Foundation

enum PlayerBuilder {
    static func apply(to plan: LevelGenerationPlan, session: GameSession) -> LevelGenerationPlan {
        var p = plan
        guard p.player == nil else { return p }

        let start = p.rooms[p.startIndex]
        let pos = Geom.center(of: start)
        p.player = PlacedPlayer(position: pos, model: session.player)
        return p
    }
}
