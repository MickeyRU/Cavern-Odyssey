import Foundation

final class FileMainRepository: MainRepositoryProtocol {
    private let file: URL
    
    init(file: URL) {
        self.file = file
    }

    func append(_ record: RunRecord) -> Result <Void, DataError> {
        guard case var .success(all) = loadAll() else {
            return .failure(.fileNotFound)
        }
        all.append(record)
        guard case .success = save(all) else {
            return .failure(.failedSaving)
        }
        return .success(())
    }

    func topByTreasures(limit: Int) -> Result <[RunRecord], DataError> {
        guard case let .success(all) = loadAll() else {
            return .failure(.fileNotFound)
        }
        let sorted = all.sorted { l, r in
            l.treasures == r.treasures ? l.levelReached > r.levelReached
                                       : l.treasures > r.treasures
        }
        return .success(Array(sorted.prefix(limit)))
    }
    
    func save(_ items: [RunRecord]) -> Result <Void, DataError> {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            try enc.encode(items).write(to: file, options: .atomic)
            return .success(())
        } catch {
            return .failure(.failedSaving)
        }
    }
    
    private func loadAll() -> Result <[RunRecord], DataError> {
       do {
           let data = try Data(contentsOf: file)
           let result = try JSONDecoder().decode([RunRecord].self, from: data)
           return .success(result)
        } catch {
            return .failure(.corruptedData)
        }
    }

}
