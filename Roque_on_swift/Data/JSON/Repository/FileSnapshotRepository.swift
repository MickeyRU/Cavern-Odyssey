import Foundation

final class FileSnapshotRepository: FileProtocol {
    typealias Entity = DomainSnapshot

    private let file: URL

    init(file: URL) {
        self.file = file
    }

    func save(_ snapshot: DomainSnapshot) -> Result <Void, DataError> {
        let dto = DomainSnapshotMapper.toDTO(from: snapshot)
        do {
            let data = try JSONEncoder().encode(dto)
            try data.write(to: file, options: .atomic)
            return .success(())
        } catch {
            return .failure(.failedSaving)
        }
    }

    func load() -> Result <DomainSnapshot, DataError> {
        do {
            let data = try Data(contentsOf: file)
            let dto = try JSONDecoder().decode(DomainSnapshotDTO.self, from: data)
            return .success(DomainSnapshotMapper.toDomain(from: dto))
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
