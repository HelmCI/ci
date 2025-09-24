## Движок генерации Releases (Helmwave Engine)

### Обзор

- Вход: `helmwave.yml.tpl` → включает `helmwave/helmwave.tpl` и шаблоны паттернов
- Выход: `helmwave.yml` — список релизов для Helmwave
- Ключевой паттерн: `helmwave/src.tpl` (current cluster by tags)
- Доп. паттерны: `helmwave/simple.tpl`, `helmwave/raw.tpl`
- Расширения: `helmwave/compose.tpl` (docker-compose), `helmwave/db.tpl` (пример Store → Releases)

### Последовательность генерации (упрощённо)

1. Определение контекста: поиск `*/src/<ctx>.yml`
2. Мердж зависимостей контекста: `src/_.yml`, `.env*.yml`, затем `*/src/lib/*.yml`
3. Формирование глобальной Store: `store.tpl` (+ `_`, `_modules`, параметры ingress/registry)
4. Построение релизов по пространствам имен и чартам из зависимостей:
   - Общие chart-values: `src/chart/general.tpl`, `src/chart/<chart>/*.tpl`
   - Библиотечные значения релизов: `src/lib/<chart>/<release>.tpl`
   - Переопределения на уровне ns: `src/ns/<ns>/<chart>/<release>.tpl`
   - Переопределения на уровне ctx: `src/context/<ctx>/<ns>/<chart>/<release>.tpl`
5. Тегирование релизов: `<ctx>`, `<ns>`, `<ns>@<release>`, `<release>` (можно отключить `manual: true`)
6. Подключение глобальной Store ко всем релизам через YAML anchors

### Docker Compose расширение

- Источник: `src/dc/*/docker-compose.yml`
- Поддержка:
  - Проброс секретов/переменных окружения
  - PVC, файловые деревья и nodeAffinity для маунтов
  - Генерация релизов через chart `app`/`busybox` в соответствии с правилами

### Параметры по умолчанию и приоритеты

1) Контекст → 2) Общие зависимости → 3) lib → 4) chart → 5) ns → 6) ctx/ns

### Отладка

- В выходном YML печатаются диагностические строки: MODULES, CONTEXT, DEPS, COMMON STORE/SECRET и т.д., со ссылками `file://` на исходники

### Модульность

- Автоматический поиск модулей идет не рекурсивно только на первом уровне; глубокие — поднимаются симлинками

### Источники

- Оригинальная подробная документация: [doc.md](doc.md)
- README модуля: [README.ru.md](../README.ru.md), [README.md](../README.md)
