import Foundation

/// Геометрические утилиты для работы с координатами и комнатами.
enum Geom {
    /// Ограничивает значение `v` в пределах диапазона [`lo`, `hi`].
    static func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { max(lo, min(v, hi)) }

    /// Манхэттенское расстояние: количество клеток,
    /// которые нужно пройти от точки `a` до `b` (по осям X и Y).
    static func manhattan(_ a: Coordinates, _ b: Coordinates) -> Int {
        abs(a.x - b.x) + abs(a.y - b.y)
    }

    /// Центр комнаты (с округлением к внутренним границам).
    static func center(of r: Room) -> Coordinates {
        let mx = (r.left + r.right) / 2
        let my = (r.top  + r.bottom) / 2
        return Coordinates(
            x: clamp(mx, r.innerLeft,  r.innerRight),
            y: clamp(my, r.innerTop,   r.innerBottom)
        )
    }

    /// Горизонтальный диапазон внутри комнаты (без стен).
    static func innerXRange(_ r: Room) -> ClosedRange<Int> { (r.left+1)...(r.right-1) }

    /// Вертикальный диапазон внутри комнаты (без стен).
    static func innerYRange(_ r: Room) -> ClosedRange<Int> { (r.top+1)...(r.bottom-1) }

    /// Пересечение двух диапазонов. Возвращает nil, если они не пересекаются.
    static func intersection(_ a: ClosedRange<Int>, _ b: ClosedRange<Int>) -> ClosedRange<Int>? {
        let lo = max(a.lowerBound, b.lowerBound)
        let hi = min(a.upperBound, b.upperBound)
        return lo <= hi ? (lo...hi) : nil
    }
}
