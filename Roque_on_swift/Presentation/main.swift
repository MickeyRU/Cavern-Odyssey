import Foundation
import Darwin


// --- ИНИЦИАЛИЗАЦИЯ ТЕРМИНАЛА ---
setupCurses()
// endwin() корректно закроет ncurses при выходе
defer { endwin()}

// --- РАЗМЕР ИГРОВОГО ПОЛЯ ---
// Берём текущий размер окна терминала как канву.
let canvas = Size(width: Int(COLS), height: Int(LINES))

// --- СТАРТОВОЕ МЕНЮ ---
let choice = Menu.showStartMenu(canvasSize: canvas)

// --- ГЕНЕРАЦИЯ УРОВНЯ / СОСТОЯНИЕ ---
let generator = SimpleLevelGenerator()

// --- ПУТИ СОХРАНЕНИЙ / РЕПОЗИТОРИИ ---
guard case let .success(savePaths) = SavePaths.load() else {
    Menu.messageError("Не удалось открыть файл")
    exit(0)
}
let repositoryRecord = FileMainRepository(file: savePaths.leaderboard)
let repositoryCurrentRecord = FileMainRepository(file: savePaths.currentRating)
let repositoryLastGame = FileSnapshotRepository(file: savePaths.lastSession)
let repositoryLastGamesession = FileGameSessionRepository(file: savePaths.lastGameSession)

// --- USE-CASES СОХРАНЕНИЯ ---
let saveUseCase = SaveSessionUseCase(repository: repositoryLastGame)
let saveGameSessionUC = SaveGameSessionUseCase(repository: repositoryLastGamesession)
let recordUseCase = AppendRunRecordUseCase(repository: repositoryCurrentRecord)
let saveRecordUseCase = AppendRunRecordUseCase(repository: repositoryRecord)


// --- ФАБРИКА STORE ---
let store = LevelStateStoreFactory.parseFirstScreenInput(choice: choice, generator: generator, canvas: canvas, paths: savePaths)

// --- DOMAIN-СЕРВИС БОЯ (чистая математика боя) ---
let battleService: BattleService = SimpleBattleService(store: store)

// --- ОСНОВНЫЕ USE-CASES ДОМЕНА ---
let actions    = PlayerActionInteractor(store: store)   // движение/инвентарь/действия игрока
let gameState  = CurrentGameStateInteractor(store: store) // снапшот доменного состояния
let lvlController = FinishLevelInteractor(store: store)   // переход уровней

// --- ЕДИНЫЙ ОРКЕСТРАТОР ИГРОВОГО ШАГА ---
let gameStepUC: GameStepUseCase = GameStepInteractor(
    gameStateUC: gameState,
    finishUC: lvlController,
    battleService: battleService,
    store: store
)

// --- ВИДИМОСТЬ (FOV + "след") ---
let visibilityUC: VisibilityUseCase = VisibilityInteractor(store: store)

// --- СБОРКА КАДРА (Domain → DTO + FOV) ---
let frameUC: BuildFrameUseCase = BuildFrameInteractor(
    gameStateUC: gameState,        // берёт DomainSnapshot
    visibilityUC: visibilityUC     // считает и обновляет FOV/explored
)

// --- КОНТРОЛЛЕР ---
// GameController – дирижёр цикла: снапшот → FOV → рендер → ввод → gameStepUC.advance → сохранение
let controller = GameController(gameState: gameState,
                                actions: actions,
                                save: saveUseCase,
                                recordUC: recordUseCase,
                                fog: VisibilityMap(),
                                gameStepUC: gameStepUC,
                                frameUC: frameUC,
                                fovRadius: 7)

// --- СТАРТ ---
clear()
refresh()
controller.run()

/// MARK: - NCurses bootstrap
/// Настраивает окружение ncurses: цвета, режимы ввода/вывода.
private func setupCurses() {
    // Локаль для корректного отображения Unicode
    _ = setlocale(LC_ALL, "")
    // 256-цветный терминал
    setenv("TERM", "xterm-256color", 1)

    initscr()
    start_color()
    use_default_colors()

    // Кастомные цвета
    let ORANGE: Int16 = 208
    let BRIGHT_GREEN: Int16 = 46
    let BRIGHT_RED: Int16 = 196
    let BRIGHT_BLUE: Int16 = 21
    let BRIGHT_YELLOW: Int16 = 226
    let GREY: Int16 = 246
    let BLACK: Int16 = Int16(COLOR_BLACK)

    // Палитра отрисовки (см. GameRenderer.ColorPair)
    init_pair(GameRenderer.ColorPair.wall.rawValue,   ORANGE,       BLACK)
    init_pair(GameRenderer.ColorPair.door.rawValue,   ORANGE,       BLACK)
    init_pair(GameRenderer.ColorPair.floor.rawValue,  BRIGHT_GREEN, BLACK)
    init_pair(GameRenderer.ColorPair.tunnel.rawValue, GREY,         BLACK)

    init_pair(GameRenderer.ColorPair.doorRed.rawValue,    BRIGHT_RED,    BLACK)
    init_pair(GameRenderer.ColorPair.doorBlue.rawValue,   BRIGHT_BLUE,   BLACK)
    init_pair(GameRenderer.ColorPair.doorYellow.rawValue, BRIGHT_YELLOW, BLACK)

    init_pair(GameRenderer.ColorPair.keyRed.rawValue,    BRIGHT_RED,    BLACK)
    init_pair(GameRenderer.ColorPair.keyBlue.rawValue,   BRIGHT_BLUE,   BLACK)
    init_pair(GameRenderer.ColorPair.keyYellow.rawValue, BRIGHT_YELLOW, BLACK)

    init_pair(GameRenderer.ColorPair.player.rawValue, Int16(COLOR_WHITE), Int16(COLOR_BLACK))

    init_pair(GameRenderer.ColorPair.zombie.rawValue,    Int16(COLOR_GREEN),  Int16(COLOR_BLACK))
    init_pair(GameRenderer.ColorPair.vampire.rawValue,   Int16(COLOR_RED),    Int16(COLOR_BLACK))
    init_pair(GameRenderer.ColorPair.ghost.rawValue,     Int16(COLOR_WHITE),  Int16(COLOR_BLACK))
    init_pair(GameRenderer.ColorPair.ogre.rawValue,      Int16(COLOR_YELLOW), Int16(COLOR_BLACK))
    init_pair(GameRenderer.ColorPair.snakeMage.rawValue, Int16(COLOR_WHITE),  Int16(COLOR_BLACK))
    init_pair(GameRenderer.ColorPair.mimic.rawValue,     Int16(COLOR_WHITE),  Int16(COLOR_BLACK))

    init_pair(12, Int16(COLOR_MAGENTA), Int16(COLOR_BLACK)) // предметы
    init_pair(13, Int16(COLOR_WHITE),   Int16(COLOR_BLACK)) // HUD
    init_pair(GameRenderer.ColorPair.exit.rawValue, Int16(COLOR_WHITE), Int16(COLOR_BLACK))

    // Режимы терминала
    cbreak()             // посимвольный ввод
    noecho()             // не отображать ввод
    keypad(stdscr, true) // поддержка функциональных клавиш
    curs_set(0)          // скрыть курсор
}
