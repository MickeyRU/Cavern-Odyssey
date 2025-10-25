import Foundation
import Darwin.ncurses

/// Простые меню и диалоги поверх сцены
enum Menu {
    /// Показать окно "Помощь"
    static func showHelp(frame: GameFrameDTO, fog: VisibilityMap) {
        // перерисовать сцену под окном
        GameRenderer.drawFrame(world: frame.world, actors: frame.actors, fog: fog, clear: true)
        PanelRenderer.drawBackdropOverlay(canvas: frame.world.canvasSize)

        let lines = [
            "WASD — движение",
            "h — оружие (0 — убрать из рук)",
            "j — съесть еду",
            "k — выпить эликсир",
            "e — прочитать свиток",
            "q — выход"
        ]
        let w = 40, h = lines.count + 4
        let x = max(0, (frame.world.canvasSize.width  - w) / 2)
        let y = max(0, (frame.world.canvasSize.height - h) / 2)

        PanelRenderer.drawPanel(x: x, y: y, w: w, h: h, title: "Меню", lines: lines)
        refresh()
        _ = getch() // закрываем по любой клавише
    }

    /// Список для выбора предмета
    /// - Returns: индекс 0...n-1, nil — отмена, -1 — «убрать» (если allowZero=true)
    static func selectFromList(title: String,
                               items: [ItemDTO],
                               allowZero: Bool,
                               frame: GameFrameDTO,
                               fog: VisibilityMap) -> Int? {
        guard !items.isEmpty else { return nil }

        // 1) фон
        GameRenderer.drawFrame(world: frame.world, actors: frame.actors, fog: fog, clear: true)
        PanelRenderer.drawBackdropOverlay(canvas: frame.world.canvasSize)

        // Показываем не больше 9 пунктов
        let visibleItems = Array(items.prefix(9))

        // 2) строки для вывода
        var lines: [String] = []
        lines.append("Выберите [1–\(visibleItems.count)]" + (allowZero ? ", 0 — убрать" : ""))
        lines.append("Esc/Q — отмена")
        lines.append("")
        for (i, it) in visibleItems.enumerated() {
            lines.append(" \(i+1). \(it.name)")
        }

        // 3) размеры панели
        // ширина — по реальной длине строк
        let maxLineLen = lines.map { $0.count }.max() ?? 10
        let w = max(30, maxLineLen + 6)

        // высота — по количеству строк + отступы панели
        let idealH = lines.count + 4
        let maxH = frame.world.canvasSize.height - 2
        let h = min(idealH, maxH)

        let x = max(0, (frame.world.canvasSize.width  - w) / 2)
        let y = max(0, (frame.world.canvasSize.height - h) / 2)

        PanelRenderer.drawPanel(x: x, y: y, w: w, h: h, title: title, lines: lines)
        refresh()

        // 4) ввод 
        while true {
            let key = getch()
            if key == 27 || key == Int32(UInt8(ascii: "q")) { return nil }
            if allowZero, key == Int32(UInt8(ascii: "0"))   { return -1 }
            if let d = keyDigit(key), d >= 1, d <= visibleItems.count { return d - 1 }
        }
    }

    // MARK: - Helpers
    private static func keyDigit(_ k: Int32) -> Int? {
        guard let us = UnicodeScalar(UInt32(k)),
              us.properties.numericType == .decimal else { return nil }
        return Int(k) - Int(UInt8(ascii: "0"))
    }
}

extension Menu {
    /// Показывает стартовое меню с выбором: новая игра или загрузка
    static func showStartMenu(canvasSize: Size) -> Int {
        // Очищаем экран
        clear()
        
        // Создаем варианты выбора
        let title = "Rogue"
        let subtitle = "Выберите действие:"
        let options = [
            "1 - Новая игра",
            "2 - Загрузить сохранение",
            "3 - Таблица рекордов"
        ]
        
        // Вычисляем размеры панели
        let maxWidth = max(title.count, subtitle.count, options.map { $0.count }.max() ?? 0) + 6
        let height = options.count + 6
        
        let x = max(0, (canvasSize.width - maxWidth) / 2)
        let y = max(0, (canvasSize.height - height) / 2)
        
        // Рисуем затемнение
        PanelRenderer.drawBackdropOverlay(canvas: canvasSize)
        
        // Рисуем панель с рамкой
        PanelRenderer.drawPanel(
            x: x,
            y: y,
            w: maxWidth,
            h: height,
            title: title,
            lines: [subtitle] + [""] + options
        )
        
        refresh()
        
        // Ожидаем ввод пользователя
        while true {
            let key = getch()
            switch key {
            case Int32(UInt8(ascii: "1")):
                return 1
            case Int32(UInt8(ascii: "2")):
                return 2
            case Int32(UInt8(ascii: "3")):
                return 3
            default:
                continue
            }
        }
    }
}

extension Menu {
    static func LeaderboardScreen (canvasSize: Size, repository: MainRepositoryProtocol) {
        let useCase = GetTopByTreasuresUseCase(repository: repository)
        guard case let .success(records) = useCase(limit: 10)
        else{
            Menu.messageError("Нет записанных рекордов")
            exit(0)
        }
        
        // Очищаем экран
        clear()
        PanelRenderer.drawBackdropOverlay(canvas: canvasSize)
        
        // Определяем размеры панели
        let title = "LEADERBOARD"
        let columnTitles = ["RANK", "NAME", "TREASURES", "LEVEL", "ENEMIES", "FOOD","POTIONS", "SCROLLS", "DEALT", "TAKEN", "CELLS"]
        let columnWidths = [4, 10, 9, 5, 5, 5, 5, 5, 5, 5, 5]
        
        let totalWidth = columnWidths.reduce(0, +) + (columnWidths.count - 1) * 3 + 4
        let height = min(20, records.count + 8) // Ограничиваем высоту
        
        let x = max(0, (canvasSize.width - totalWidth) / 2)
        let y = max(0, (canvasSize.height - height) / 2)
        
        // Рисуем панель
        PanelRenderer.drawPanel(x: x, y: y, w: totalWidth, h: height, title: title, lines:[])
        
        // Заголовки столбцов
        var currentX = x + 2
        for (index, columnTitle) in columnTitles.enumerated() {
            mvaddstr(Int32(y + 2), Int32(currentX), columnTitle)
            currentX += columnWidths[index] + 3
        }
        
        // Данные
        for (index, record) in records.enumerated() {
            let row = y + 4 + index
            // Заполняем данные
            currentX = x + 2
            
            // Ранг
            mvaddstr(Int32(row), Int32(currentX), "\(index + 1)")
            currentX += columnWidths[0] + 3
            
            // Имя
            let name = String(record.playerName.prefix(columnWidths[1] - 1))
            mvaddstr(Int32(row), Int32(currentX), name)
            currentX += columnWidths[1] + 3
            
            // Сокровища
            mvaddstr(Int32(row), Int32(currentX), "\(record.treasures)")
            currentX += columnWidths[2] + 3
            
            // Уровень
            mvaddstr(Int32(row), Int32(currentX), "\(record.levelReached)")
            currentX += columnWidths[3] + 3
            
            // Враги
            mvaddstr(Int32(row), Int32(currentX), "\(record.enemiesDefeated)")
            currentX += columnWidths[4] + 3

            // еда
            mvaddstr(Int32(row), Int32(currentX), "\(record.foodEaten)")
            currentX += columnWidths[5] + 3
            // зелья
            mvaddstr(Int32(row), Int32(currentX), "\(record.potionsDrunk)")
            currentX += columnWidths[6] + 3
            // свитки
            mvaddstr(Int32(row), Int32(currentX), "\(record.scrollsRead)")
            currentX += columnWidths[7] + 3
            // нанесено ударов
            mvaddstr(Int32(row), Int32(currentX), "\(record.hitsDealt)")
            currentX += columnWidths[8] + 3
            // получено
            mvaddstr(Int32(row), Int32(currentX), "\(record.hitsTaken)")
            currentX += columnWidths[9] + 3
            // клетки
            mvaddstr(Int32(row), Int32(currentX), "\(record.cellsWalked)")
            currentX += columnWidths[10] + 3
        }
        // Инструкция
        mvaddstr(Int32(y + height - 2), Int32(x + 2), "Нажмите любую клавишу для выхода")
        
        refresh()
        
        // Ждем любую клавишу
        _ = getch()
    }
}

extension Menu {
    static func AskPlayerNameScreen(canvasSize: Size) -> String {
        let prompt = "Введите имя вашего персонажа: "
        let maxLength = 20
        let startX = (canvasSize.width - prompt.count - maxLength) / 2
        let startY = canvasSize.height / 2

        // Очистим экран
        clear()

        // Выводим подсказку
        mvaddstr(Int32(startY), Int32(startX), prompt)

        // Ввод
        echo()
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: maxLength + 1)
        defer { buffer.deallocate() }

        mvgetnstr(Int32(startY), Int32(startX + prompt.count), buffer, Int32(maxLength))
        noecho()

        let input = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)

        return input.isEmpty ? "Герой" : input
    }
}

extension Menu {
    static func messageError (_ message: String) {
        clear()
        mvaddstr(10, 5, message)
        mvaddstr(12, 5, "Нажмите любую клавишу для выхода")
        refresh()
        getch()
        exit(0)
    }
}
