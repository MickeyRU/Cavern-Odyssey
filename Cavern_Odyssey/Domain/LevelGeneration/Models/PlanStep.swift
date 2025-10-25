import Foundation

// MARK: - Шаг пайплайна

/// Единый интерфейс для всех «билдеров»/шагов генерации.
/// Каждый шаг принимает актуальный план и возвращает новый.
protocol PlanStep {
    static func apply(to plan: LevelGenerationPlan, depth: Int) -> LevelGenerationPlan
}
