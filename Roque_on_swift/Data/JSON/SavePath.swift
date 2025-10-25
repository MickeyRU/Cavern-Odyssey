import Foundation

struct SavePaths {
    let leaderboard: URL
    let lastSession: URL
    let lastGameSession: URL
    let currentRating: URL

    init() throws {
        let fm = FileManager.default

        //MARK: Лидерборд
        let leaderboardKey = "LEADERBOARD_FILE"
        let snapshotKey = "LAST_GAME_FILE"
        let gameSessionKey = "LAST_GAMESESSION_FILE"
        let currentRatingKey = "CURRENT_RATING"

        guard let leaderboardRaw = ProcessInfo.processInfo.environment[leaderboardKey],
              !leaderboardRaw.isEmpty,
              let snapshotRaw = ProcessInfo.processInfo.environment[snapshotKey],
              !snapshotRaw.isEmpty,
              let gameSessionRaw = ProcessInfo.processInfo.environment[gameSessionKey],
              !gameSessionRaw.isEmpty,
              let currentRatingRaw = ProcessInfo.processInfo.environment[currentRatingKey],
              !currentRatingRaw.isEmpty
        else {
            throw DataError.environmentVariable
        }
        let leaderboardURL = URL(fileURLWithPath: leaderboardRaw)
        let snapshotURL = URL(fileURLWithPath: snapshotRaw)
        let gameSessionURL = URL(fileURLWithPath: gameSessionRaw)
        let currentRatingURL = URL(fileURLWithPath: currentRatingRaw)

        guard fm.fileExists(atPath: leaderboardURL.path),
              fm.fileExists(atPath: snapshotURL.path),
              fm.fileExists(atPath: gameSessionURL.path),
              fm.fileExists(atPath: currentRatingURL.path)
        else {
            throw DataError.fileNotFound
        }
        
        self.leaderboard = leaderboardURL
        self.lastSession = snapshotURL
        self.lastGameSession = gameSessionURL
        self.currentRating = currentRatingURL
    }
}


extension SavePaths {
    static func load() -> Result<SavePaths, DataError> {
        do {
            let result = try SavePaths()
            return .success(result)
        } catch DataError.environmentVariable {
            return .failure(.environmentVariable)
        } catch {
            return .failure(.fileNotFound)
        }
    }
}
