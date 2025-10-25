import Foundation

struct AppendRunRecordUseCase {
    private let repo: MainRepositoryProtocol
    init(repository: MainRepositoryProtocol) { self.repo = repository }
    func callAsFunction(_ r: RunRecord) -> Result <Void, DataError> { repo.append(r) }
    func saveCurrentRating(_ r: RunRecord) -> Result <Void, DataError> { repo.save([r]) }
}

struct GetTopByTreasuresUseCase {
    private let repo: MainRepositoryProtocol
    init(repository: MainRepositoryProtocol) { self.repo = repository }
    func callAsFunction(limit: Int) -> Result <[RunRecord], DataError> {
        repo.topByTreasures(limit: limit)
    }
}
