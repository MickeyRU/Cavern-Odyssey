# 🧭 Cavern Odyssey

**Cavern Odyssey** — консольная пошаговая игра-приключение, написанная на **Swift** с использованием **ncurses**.  
Игрок исследует подземелья, сражается с врагами, собирает предметы и постепенно открывает новые области.  
Проект демонстрирует принципы чистой архитектуры (Domain / Data / Presentation) и детерминированный игровой цикл.

---

## 🎮 Особенности
- Процедурная генерация комнат и коридоров с гарантированной связностью уровня.  
- Пошаговая механика: мир реагирует только на действия игрока.  
- Расчёт поля видимости (FOV) и туман войны.  
- Инвентарь: оружие, пища, эликсиры, свитки, сокровища.  
- Сохранение и загрузка прогресса в формате **JSON**.  
- Противники с разными типами поведения и характеристиками.  
- Архитектура проекта разделена на слои **Domain / Data / Presentation**.

---

## ⚙️ Технологии
- **Язык:** Swift 5.10+  
- **Интерфейс:** ncurses (Text User Interface)  
- **Архитектура:** Domain / Data / Presentation  
- **Формат сохранений:** JSON  
- **Поддержка UTF-8** для отображения символов и рамок в терминале.

---

## 🕹 Управление
| Действие | Клавиша |
|-----------|----------|
| Движение | **W / A / S / D** |
| Сменить оружие | **h** |
| Использовать пищу | **j** |
| Использовать эликсир | **k** |
| Прочитать свиток | **e** |
| Выход | **q** |

---

## 📸 Скриншоты

<table>
    <thead>
        <tr>
            <th>Меню</th>
            <th>Геймплей</th>
            <th>Айтемы</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
                <img src="https://github.com/user-attachments/assets/27906599-12ba-4b19-8962-d45246a1a36a" style="max-width: 100%; height: auto;" />
            </td>
            <td>
                <img src="https://github.com/user-attachments/assets/328c2715-d70e-4abd-8184-e2567072c7b0" style="max-width: 100%; height: auto;" />
            </td>
            <td>
                <img src="https://github.com/user-attachments/assets/e456833a-57aa-4df8-addd-0abc294e5231" style="max-width: 100%; height: auto;" />
            </td>
        </tr>
    </tbody>
</table>

---

## Авторы
<a href="https://github.com/MickeyRU"><img src="https://github.com/MickeyRU.png" width="50" height="50" /></a>
<a href="https://github.com/Arrow-srt"><img src="https://github.com/Arrow-srt.png" width="50" height="50" /></a>
<a href="https://github.com/candarly"><img src="https://github.com/candarly.png" width="50" height="50" /></a>
