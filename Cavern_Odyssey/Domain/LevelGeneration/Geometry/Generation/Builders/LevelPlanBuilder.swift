import Foundation

struct LevelPlanBuilder {
    let canvas: Size

    func buildRooms() -> LevelGenerationPlan {
        let worldCanvas = Size(width: canvas.width, height: max(1, canvas.height - 1))

        let outer = 6
        let innerLeft = outer, innerTop = outer
        let innerRight = worldCanvas.width - 1 - outer
        let innerBottom = worldCanvas.height - 1 - outer
        let innerW = max(1, innerRight - innerLeft + 1)
        let innerH = max(1, innerBottom - innerTop + 1)

        let w3 = innerW / 3, h3 = innerH / 3
        let colXs = [innerLeft, innerLeft + w3, innerLeft + 2*w3, innerLeft + innerW]
        let rowYs = [innerTop,  innerTop  + h3, innerTop  + 2*h3, innerTop  + innerH]
        func sector(_ c: Int, _ r: Int) -> (x0: Int, y0: Int, x1: Int, y1: Int) {
            (colXs[c], rowYs[r], colXs[c+1]-1, rowYs[r+1]-1)
        }

        let roomFactory = RoomFactory(
            config: .init(minWidth: 6, minHeight: 5, sectorMarginX: 2, sectorMarginY: 1)
        )

        var rooms: [Room] = []
        rooms.reserveCapacity(9)
        for r in 0..<3 {
            for c in 0..<3 {
                let s = sector(c, r)
                rooms.append(roomFactory.makeRandomRoom(inSector: s.x0, s.y0, s.x1, s.y1))
            }
        }

        return LevelGenerationPlan(
            canvasSize: worldCanvas,
            rooms: rooms,
            edges: [],
            doorLinks: [],
            corridors: [],
            startIndex: 0,
            exitIndex: nil,
            items: [],
            enemies: []
        )
    }
}
