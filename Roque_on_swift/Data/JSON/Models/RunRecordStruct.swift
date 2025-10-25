// MARK: DTO for leaderboard

final class RunRecord: Codable {
    static let addRecord = RunRecord()
    
    private init() {}
    
    var playerName = ""
    var treasures = 0
    var levelReached = 1
    var enemiesDefeated = 0
    var foodEaten = 0
    var potionsDrunk = 0
    var scrollsRead = 0
    var hitsDealt = 0
    var hitsTaken = 0
    var cellsWalked = 0
}

