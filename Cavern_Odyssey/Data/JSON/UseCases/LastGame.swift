import Foundation
struct SaveSessionUseCase {
    let repository: FileSnapshotRepository
    
    func callAsFunction(snapshot: DomainSnapshot) -> Result <Void, DataError> {
        repository.save(snapshot)
    }
    func clean () -> Result <Void, DataError> {
        repository.clean()
    }
}

struct LoadSessionUseCase  {
    let repository: FileSnapshotRepository
    
    func callAsFunction() ->  Result <DomainSnapshot, DataError>{
        return repository.load()
    }
}

struct LoadGameSessionUseCase {
    let repository: FileGameSessionRepository

    func callAsFunction() ->  Result <GameSession, DataError>{
        return repository.load()
    }
}

struct SaveGameSessionUseCase {
    let repository: FileGameSessionRepository

    func callAsFunction(session: GameSession) -> Result <Void, DataError>  {
        repository.save(session)
    }
    func clean () -> Result <Void, DataError> {
        repository.clean()
    }
}
