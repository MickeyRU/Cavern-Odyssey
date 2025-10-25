import Foundation

final class FileGameSessionRepository: FileProtocol {
    typealias Entity = GameSession

    private let file: URL

    init(file: URL) {
        self.file = file
    }

    func save(_ session: GameSession)  -> Result <Void, DataError> {
        let dto = GameSessionMapper.toDTO(from: session)
        do {
            let data = try JSONEncoder().encode(dto)
            try data.write(to: file, options: .atomic)
            return .success(())
        } catch {
            return .failure(.failedSaving)
        }
    }

    func load() -> Result <GameSession, DataError> {
        do {
            let data = try Data(contentsOf: file)
            let dto = try JSONDecoder().decode(GameSessionDTO.self, from: data)
            return .success(GameSessionMapper.toDomain(from: dto)) 
        } catch {
            return .failure(.corruptedData)
        }
    }
    func clean() -> Result <Void, DataError>  {
        do {
            let emptyArray = try JSONEncoder().encode([RunRecord]())
            try emptyArray.write(to: file, options: .atomic)
            return .success(())
        } catch {
            return .failure(.fileNotFound)
        }
    }
}
