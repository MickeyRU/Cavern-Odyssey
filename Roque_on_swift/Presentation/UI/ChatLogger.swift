import Foundation
import Darwin.ncurses

// Система логгирования сообщений в чат
final class ChatLogger {
    static let shared = ChatLogger()
    
    private var messages: [String] = []
    private let maxMessages = 5        // сколько строк показываем
    private let maxStored   = 50       // сколько всего храним
    
    private init() {}
    
    func addMessage(_ message: String) {
        messages.append(message)
        if messages.count > maxStored {
            messages.removeFirst(messages.count - maxStored)
        }
    }
    
    /// Рисует чат: 4 строки снизу, разделитель — на 5-й снизу.
    func drawChat(on canvas: Size) {
        guard canvas.height >= maxMessages + 1 else { return } // не помещается
        
        let width  = canvas.width
        let startY = canvas.height - (maxMessages)
        let endY   = canvas.height - 1
        
        // Очистить область чата
        for y in startY...endY {
            for x in 0..<width { mvaddstr(Int32(y), Int32(x), " ") }
        }
        
        // Показать последние maxMessages сообщений, снизу-вверх
        let visible = Array(messages.suffix(maxMessages))
        let rowsToDraw = min(visible.count, maxMessages)
        
        for i in 0..<rowsToDraw {
            let msgIdx = visible.count - rowsToDraw + i
            let y = startY + i // идём сверху вниз в пределах блока чата
            
            // обрежем строку по ширине, чтобы не "вылезала"
            let line = visible[msgIdx]
            let clipped = String(line.prefix(width))
            
            _ = clipped.withCString { mvaddstr(Int32(y), 0, $0) }
        }
    }
    
    func clearChat() {
        messages.removeAll()
    }
}
