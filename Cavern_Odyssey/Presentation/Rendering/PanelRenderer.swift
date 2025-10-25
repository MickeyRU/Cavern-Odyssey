import Foundation
import Darwin.ncurses

enum PanelRenderer { // internal
    /// Полупрозрачная «подложка» поверх кадра (просто затемнение символами/цветом).
    static func drawBackdropOverlay(canvas: Size) {
        for y in 0..<canvas.height {
            for x in 0..<canvas.width {
                mvaddstr(Int32(y), Int32(x), " ")
            }
        }
    }

    /// Рисуем простую рамочную панель с заголовком и строками.
    static func drawPanel(x: Int, y: Int, w: Int, h: Int, title: String?, lines: [String]) {
        // рамка
        for i in 0..<w {
            mvaddstr(Int32(y),           Int32(x+i), "─")
            mvaddstr(Int32(y + h - 1),   Int32(x+i), "─")
        }
        for j in 0..<h {
            mvaddstr(Int32(y+j), Int32(x),         "│")
            mvaddstr(Int32(y+j), Int32(x + w - 1), "│")
        }
        mvaddstr(Int32(y),         Int32(x),         "┌")
        mvaddstr(Int32(y),         Int32(x + w - 1), "┐")
        mvaddstr(Int32(y + h - 1), Int32(x),         "└")
        mvaddstr(Int32(y + h - 1), Int32(x + w - 1), "┘")

        if let t = title {
            _ = (" " + t + " ").withCString { mvaddstr(Int32(y), Int32(x + 2), $0) }
        }

        // контент
        var row = y + 1
        for line in lines.prefix(h - 2) {
            _ = line.withCString { mvaddstr(Int32(row), Int32(x + 2), $0) }
            row += 1
        }
    }
}
