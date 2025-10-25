import Foundation

protocol MainRepositoryProtocol {
    func append(_ record: RunRecord) -> Result <Void, DataError>
    func topByTreasures(limit: Int) -> Result <[RunRecord], DataError>
    func save(_ items: [RunRecord]) -> Result <Void, DataError> 
}

protocol FileProtocol {
    associatedtype Entity
    
    func save(_ session: Entity) -> Result <Void, DataError>
    func load() -> Result <Entity, DataError>
    func clean() -> Result <Void, DataError>
}

// Ошибки
enum DataError: Error {
    case fileNotFound
    case corruptedData
    case failedSaving
    case environmentVariable
}

