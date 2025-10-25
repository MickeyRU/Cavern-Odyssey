import Foundation
import Darwin.ncurses

/// Главный контроллер игры.
/// Оркеструет UI-цикл:
/// 1) запрашивает у BuildFrameUseCase готовый кадр (DTO) и видимость,
/// 2) рендерит кадр,
/// 3) читает ввод и мапит его в PlayerAction,
/// 4) передаёт результат хода игрока в GameStepUseCase (единый «тик»),
/// 5) сохраняет снапшот.
final class GameController {
    // MARK: - Use Cases (Application/Domain)
    private let gameStateUC: CurrentGameStateUseCase
    private let playerUC: PlayerActionUseCase
    private let saveUC: SaveSessionUseCase
    private let recordUseCase: AppendRunRecordUseCase
    private let gameStepUC: GameStepUseCase               // оркестратор шага
    private let frameUC: BuildFrameUseCase                // сборка кадра + FOV
    
    // MARK: - Render/FOV
    /// Состояние тумана войны (visible/seen на уровне
    private var fog: VisibilityMap
    /// Радиус обзора для FOV (в клетках)
    private let fovRadius: Int
    
    init(gameState: CurrentGameStateUseCase,
         actions: PlayerActionUseCase,
         save: SaveSessionUseCase,
         recordUC: AppendRunRecordUseCase,
         fog: VisibilityMap,
         gameStepUC: GameStepUseCase,
         frameUC: BuildFrameUseCase,
         fovRadius: Int = 5) {
        self.gameStateUC = gameState
        self.playerUC = actions
        self.saveUC = save
        self.recordUseCase = recordUC
        self.fog = fog
        self.gameStepUC = gameStepUC
        self.frameUC = frameUC
        self.fovRadius = fovRadius
    }
    
    /// Точка входа: запускает главный цикл
    func run() { mainLoop() }
}

// MARK: - Main loop
private extension GameController {
    /// Главный игровой цикл:
    /// 1) получаем снапшот и пересчитываем FOV
    /// 2) рендерим кадр
    /// 3) читаем ввод
    /// 4) обрабатываем действие
    /// 5) сохранение данных в LastGame
    func mainLoop() {
        while true {
            // 1) Кадр + видимость
            let built = frameUC.buildFrame(fovRadius: fovRadius)
            fog.visible = built.visible
            fog.seenByLevel = built.explored
            
            // 2) рендер
            render(built.frame)
            
            // 3) ввод
            let input = readInput()
            if input == .quit { break }
            
            // 4) маппим ввод → PlayerAction и исполняем
            let playerResult = handle(input, frame: built.frame)
            
            // 5) единый оркестратор «тика»
            let directive = gameStepUC.advance(after: playerResult)
            
            switch directive {
            case .gameOver:
                ChatLogger.shared.addMessage("💀 Игра окончена. Нажмите любую клавишу…")
                let finalBuilt = frameUC.buildFrame(fovRadius: fovRadius)
                guard case .success = saveRecordUseCase.callAsFunction(RunRecord.addRecord),
                      case .success = saveUC.clean()
                else {
                    Menu.messageError("Не удалось сохранить в общие рекорды")
                    exit(0)
                }
                fog.visible = finalBuilt.visible
                fog.seenByLevel = finalBuilt.explored
                render(finalBuilt.frame)
                _ = getch(); exit(0)
                
            case .gameCompleted:
                ChatLogger.shared.addMessage("🏆 Вы выбрались! Нажмите любую клавишу…")
                RunRecord.addRecord.levelReached += 1
                guard case .success = saveRecordUseCase.callAsFunction(RunRecord.addRecord)
                else {
                    Menu.messageError("Не удалось сохранить в общие рекорды")
                    exit(0)
                }
                let finalBuilt = frameUC.buildFrame(fovRadius: fovRadius)
                fog.visible = finalBuilt.visible
                fog.seenByLevel = finalBuilt.explored
                render(finalBuilt.frame)
                _ = getch(); exit(0)
                
            case .levelCompleted:
                fog.visible.removeAll()
                fog.seenByLevel.removeAll()
                ChatLogger.shared.addMessage("⬇️ Спускаемся глубже…")
                RunRecord.addRecord.levelReached += 1
                updateRecord()
            case .continueGame:
                break
            }
            
            // 6) сохранение
            handleSaveGame()
            upCellWalked ()
        }
    }
}

// MARK: - Rendering
private extension GameController {
    /// Отрисовка окружения/актеров и HUD
    func render(_ frame: GameFrameDTO) {
        GameRenderer.drawFrame(world: frame.world, actors: frame.actors, fog: fog, clear: true)
        GameRenderer.drawHUD(frame.hud, on: frame.world.canvasSize)
        refresh()
    }
}

// MARK: - Input
/// Направления для движения
fileprivate enum Direction { case up, down, left, right }

/// Высокоуровневые команды ввода (UI-слой)
fileprivate enum Input: Equatable {
    case move(Direction)
    case openWeaponMenu
    case openFoodMenu
    case openPotionMenu
    case openScrollMenu
    case openHelp
    case quit
    case none
}

private extension GameController {
    /// Считываем клавишу из ncurses и конвертим в команду `Input`.
    /// - WASD — движение
    /// - h/j/k/e — меню
    /// - ? — справка
    /// - q — выход
    func readInput() -> Input {
        let k = getch()
        switch k {
        case Int32(UInt8(ascii: "q")): return .quit
        case Int32(UInt8(ascii: "?")): return .openHelp
            
        case Int32(UInt8(ascii: "w")): return .move(.up)
        case Int32(UInt8(ascii: "s")): return .move(.down)
        case Int32(UInt8(ascii: "a")): return .move(.left)
        case Int32(UInt8(ascii: "d")): return .move(.right)
            
        case Int32(UInt8(ascii: "h")): return .openWeaponMenu
        case Int32(UInt8(ascii: "j")): return .openFoodMenu
        case Int32(UInt8(ascii: "k")): return .openPotionMenu
        case Int32(UInt8(ascii: "e")): return .openScrollMenu
            
        default: return .none
        }
    }
}

// MARK: - Input handling → PlayerActionResult
private extension GameController {
    /// Маппит `Input` в доменный `PlayerAction` и исполняет через `playerUC`.
    /// Модальные меню (оружие/еда/эликсиры/свитки) возвращают `.noOp`, если выбор не сделан.
    func handle(_ input: Input, frame: GameFrameDTO) -> PlayerActionOutcome {
        switch input {
        case .quit:
            // Нейтральный результат, чтобы GameStepUC мог корректно продолжить
            return .moved
            
        case .openHelp:
            Menu.showHelp(frame: frame, fog: fog)
            return .moved
            
        case .move(let dir):
            let action: PlayerAction = {
                switch dir {
                case .up: return .moveUp
                case .down: return .moveDown
                case .left: return .moveLeft
                case .right: return .moveRight
                }
            }()
            return playerUC.execute(action)
            
        case .openWeaponMenu:
            if let idx = Menu.selectFromList(title: "Оружие",
                                             items: frame.actors.player.inventory.weapons,
                                             allowZero: true,
                                             frame: frame, fog: fog) {
                let a: PlayerAction = (idx == -1) ? .equipWeapon(nil) : .equipWeapon(idx)
                return playerUC.execute(a)
            }
            return .blockedTerrain
            
        case .openFoodMenu:
            if let idx = Menu.selectFromList(title: "Еда",
                                             items: frame.actors.player.inventory.foods,
                                             allowZero: false,
                                             frame: frame, fog: fog) {
                return playerUC.execute(.eatFood(idx))
            }
            return .blockedTerrain
            
        case .openPotionMenu:
            if let idx = Menu.selectFromList(title: "Эликсиры",
                                             items: frame.actors.player.inventory.potions,
                                             allowZero: false,
                                             frame: frame, fog: fog) {
                return playerUC.execute(.drinkPotion(idx))
            }
            return .blockedTerrain
            
        case .openScrollMenu:
            if let idx = Menu.selectFromList(title: "Свитки",
                                             items: frame.actors.player.inventory.scrolls,
                                             allowZero: false,
                                             frame: frame, fog: fog) {
                return playerUC.execute(.readScroll(idx))
            }
            return .blockedTerrain
            
        case .none:
            return .blockedTerrain
        }
    }
}

// MARK: - Persistence
private extension GameController {
    private func handleSaveGame() {
        guard case let .success(snapshot) = gameStateUC.execute(),
              case .success = saveUC(snapshot: snapshot)
        else {
            return
        }
    }
}
extension GameController {
    private func upCellWalked () {
        RunRecord.addRecord.cellsWalked += 1
    }
    private func updateRecord() {
            guard case .success = recordUseCase.saveCurrentRating(RunRecord.addRecord)
            else {
                Menu.messageError("Не удалось сохранить рекорд")
                exit(0)
            }
        }

}
