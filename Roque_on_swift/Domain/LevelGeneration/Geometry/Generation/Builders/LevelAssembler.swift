import Foundation

// MARK: - Сборка окончательного LevelState

/// Преобразует внутренний план в боевой LevelState.
/// Здесь же выполняем «прищёлкивание» и валидацию геометрии.
struct LevelAssembler {
    static func assemble(plan: LevelGenerationPlan,
                         depth: Int,
                         playerModel: Character) -> LevelState {
        // exitIndex должен быть выбран к моменту сборки
        precondition(plan.exitIndex != nil, "ExitSelector должен заполнить exitIndex до сборки уровня")

        // 1) Геометрия
        let geo = GeometrySnapshot(
            canvasSize: plan.canvasSize,
            rooms:      plan.rooms,
            corridors:  plan.corridors
        )
        let snapped = EnvironmentValidator.snapped(geo)
        try? EnvironmentValidator.validate(snapped)

        // 2) Игрок (ставим в стартовую комнату по центру внутренней области)
        let startRoom = plan.rooms[plan.startIndex]
        let playerPos = Geom.center(of: startRoom)
        
        let player    = PlacedPlayer(position: playerPos, model: playerModel)

        // 3) Враги и предметы — уже подготовлены шагами пайплайна
        let enemies = plan.enemies
        let items   = plan.items

        // 4) HUD
        let hud = DomainHUD(
            weaponName: playerModel.currentWeapon?.name,
            gold: playerModel.gold,
            hp: playerModel.currentHealth,
            maxHP: playerModel.maxHealth,
            depth: depth,
            inventorySummary: ""
        )

        // 5) Готовый LevelState
        return LevelState(
            geometry:   snapped,
            player:     player,
            enemies:    enemies,
            hud:        hud,
            worldItems: items)
    }
}
