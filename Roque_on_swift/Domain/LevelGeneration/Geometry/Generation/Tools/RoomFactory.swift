import Foundation

/// Фабрика генерации комнат внутри секторов уровня.
/// Каждый сектор (ячейка сетки 3×3) может содержать одну комнату.
/// Генератор гарантирует минимальные размеры и небольшие отступы от краёв сектора.
struct RoomFactory {
    
    /// Конфигурация фабрики:
    /// - `minWidth`, `minHeight`: минимальные размеры комнаты.
    /// - `sectorMarginX`, `sectorMarginY`: отступы от границ сектора,
    ///   чтобы комнаты не прилипали к соседям вплотную.
    struct Config {
        var minWidth: Int = 6
        var minHeight: Int = 5
        var sectorMarginX: Int = 2
        var sectorMarginY: Int = 1
    }

    private let cfg: Config
    
    init(config: Config = .init()) {
        self.cfg = config
    }

    /// Создаёт случайную прямоугольную комнату внутри заданного сектора.
    ///
    /// - Parameters:
    ///   - x0, y0: координаты верхнего-левого угла сектора.
    ///   - x1, y1: координаты нижнего-правого угла сектора.
    /// - Returns: комнату (`Room`), гарантированно помещающуюся в сектор.
    ///
    /// Алгоритм:
    /// 1. Вычисляем внутреннюю область сектора (с учётом margin).
    /// 2. Определяем максимально доступные размеры (`spanW`, `spanH`).
    /// 3. Случайно выбираем ширину и высоту в допустимых пределах.
    /// 4. Случайно смещаем комнату так, чтобы она не выходила за границы сектора.
    /// 5. Возвращаем `Room` без дверей (двери будут добавлены позже).
    func makeRandomRoom(inSector x0: Int, _ y0: Int, _ x1: Int, _ y1: Int) -> Room {
        // 1) допустимая внутренняя область сектора
        let sx0 = x0 + cfg.sectorMarginX
        let sy0 = y0 + cfg.sectorMarginY
        let sx1 = x1 - cfg.sectorMarginX
        let sy1 = y1 - cfg.sectorMarginY

        // 2) максимально возможная ширина и высота в этом секторе
        let spanW = max(cfg.minWidth,  sx1 - sx0 + 1)
        let spanH = max(cfg.minHeight, sy1 - sy0 + 1)

        // 3) случайная ширина и высота (не меньше минимальных)
        let rw = Int.random(in: cfg.minWidth...spanW)
        let rh = Int.random(in: cfg.minHeight...spanH)

        // 4) случайное смещение внутри сектора
        let dxMax = max(0, spanW - rw)
        let dyMax = max(0, spanH - rh)
        let dx = (dxMax > 0) ? Int.random(in: 0...dxMax) : 0
        let dy = (dyMax > 0) ? Int.random(in: 0...dyMax) : 0

        // 5) верхний-левый угол комнаты
        let left = sx0 + dx
        let top  = sy0 + dy

        return Room(
            origin: Coordinates(x: left, y: top),
            width:  rw,
            height: rh,
            doors: [] // двери будут добавлены фабрикой дверей
        )
    }
}
