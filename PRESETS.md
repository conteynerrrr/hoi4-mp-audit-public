# Пресеты для разбора основных действий в HOI4 MP Audit

[Русский](PRESETS.md) | [English](PRESETS.en.md)

Профили ориентированы на удаление складского снаряжения и юнитов, отмену и изменение перемещений. Здесь «склад» означает запас снаряжения; снос зданий/объектов снабжения — отдельные команды, часть которых относится к Construction.

## Что обязательно включено

| Класс | Что отслеживается |
|---|---|
| `CStockpiledEquipmentDeleteCommand` | Удаление складского снаряжения |
| `CDeleteUnitCommand` | Удаление/расформирование юнита |
| `CMoveCommand` | Перемещение |
| `CMassMoveCommand` | Массовое перемещение |
| `CCancelMovementCommand` | Отмена перемещения |
| `CMassCancelMovementCommand` | Массовая отмена перемещений |
| `CStrategicRedeploymentCommand` | Стратегическая передислокация |

В обычных активных профилях эти классы явно включены через [commands], поэтому выключение категории Movement само по себе их не исключит. Для отключения конкретного класса измените его значение в [commands]. Фильтры источника/отправителя продолжают действовать. В диагностическом профиле включены все категории; профиль паузы не пишет новые игровые команды.

Это наблюдение команд, а не доказательство успешного действия или намеренного гриферства. Отдельная расшифровка параметров массовых перемещений пока отсутствует: сохраняются доступные сведения, но журнал не гарантирует названия юнитов и пункт назначения.

## Выбрать профиль

| Файл | Назначение | Особенности |
|---|---|---|
| [Основные действия](presets/core-actions.ini) | `core-actions.ini` | Только семь ключевых классов: складское снаряжение, юниты, одиночные и массовые перемещения/отмены, передислокация. |
| [Основной для партии](presets/balanced.ini) | `balanced.ini` | Ключевые действия плюс производство, театры, строительство, шаблоны и развёртывание. Политика, авиационные миссии и интерфейс выключены. |
| [Расширенный разбор](presets/extended.ini) | `extended.ini` | Ключевые действия и все игровые категории, включая боевые приказы, политику, дипломатию и авиацию. Без служебной сети и интерфейса. |
| [Основной с ИИ](presets/with-ai.ini) | `with-ai.ini` | Как основной, но распознанные команды ИИ тоже сохраняются. Внутренние классы ИИ отдельно не включаются. |
| [Диагностика](presets/diagnostic.ini) | `diagnostic.ini` | Все категории и источники, raw-данные, полный JSON. Для исследования пропусков. |
| [Авторский](presets/author-current.ini) | `author-current.ini` | Текущие настройки автора с явным включением семи ключевых команд. OnlyKnownPlayers=1 сохранён. |
| [Пауза](presets/paused.ini) | `paused.ini` | Основной профиль с Enabled=0. Для паузы своего конфига достаточно изменить только Enabled. |

**Начать лучше с balanced.ini.** Для минимального журнала только основных действий — core-actions.ini.

## Применить

1. Сохраните копию своего mp_audit.ini.
2. Выбранный INI скопируйте рядом с hoi4.exe и назовите mp_audit.ini.
3. Проверьте LogDirectory: во всех профилях он взят из соответствующего базового конфига.
4. Большинство ключей применяется примерно за две секунды; изменение LogDirectory и TrackCommandOrigins требует перезапуска.

Пресет заменяет весь файл, включая личные исключения. Игровой INI автоматически не меняется при скачивании профиля. Подробности: [SETTINGS.md](SETTINGS.md).

## Источники и возможные пропуски

- Обычные профили имеют OnlyKnownPlayers=0: полезная команда без найденного ника не отбрасывается только из-за отсутствия участника в списке.
- В авторском оставлено OnlyKnownPlayers=1. Такие записи могут быть пропущены, даже если класс включён. Это не проверка человека.
- SkipEngineAICommands=1 исключает подтверждённый engine_ai; неизвестный источник не объявляется ИИ. Диагностический профиль и профиль «с ИИ» сохраняют распознанный ИИ.
- SkipEmptyUnknownCommands=1 исключает только пустую диагностику. Диагностический профиль сохраняет её.
- Удаления не объединяются. Группировка хранения сейчас поддерживает только CMoveCommand, CCancelMovementCommand, CStrategicRedeploymentCommand. Массовые классы фиксируются отдельными командами; число затронутых юнитов не вычисляется. Серия не доказывает один клик.
- Gzip сжимает завершённые части без потери данных. Исключённые фильтрами команды восстановить нельзя.

## Авторский профиль

Основан на текущем игровом INI автора. Сохранены все остальные настройки, включая OnlyKnownPlayers=1, Movement/BattleOrders/Interface=1 и CSelectEventOptionCommand=0. Добавлены только явные включения семи ключевых классов. При совпадении фильтров запись всё ещё может быть исключена.

## Полные конфиги

### Основные действия

Только семь ключевых классов: складское снаряжение, юниты, одиночные и массовые перемещения/отмены, передислокация.

[Скачать core-actions.ini](presets/core-actions.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: core-actions.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=1
CaptureAllCommands=0
IncludeRawPayload=0
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=0
Equipment=0
Production=0
Theaters=0
Construction=0
Templates=0
Politics=0
Diplomacy=0
Deployment=0
AirNavy=0
Movement=0
BattleOrders=0
Network=0
AIInternal=0
Interface=0
Other=0

[commands]
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
CSelectEventOptionCommand=0
```

</details>

### Основной для партии

Ключевые действия плюс производство, театры, строительство, шаблоны и развёртывание. Политика, авиационные миссии и интерфейс выключены.

[Скачать balanced.ini](presets/balanced.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: balanced.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=1
CaptureAllCommands=0
IncludeRawPayload=0
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=0
Diplomacy=0
Deployment=1
AirNavy=0
Movement=1
BattleOrders=0
Network=0
AIInternal=0
Interface=0
Other=0

[commands]
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
CSelectEventOptionCommand=0
```

</details>

### Расширенный разбор

Ключевые действия и все игровые категории, включая боевые приказы, политику, дипломатию и авиацию. Без служебной сети и интерфейса.

[Скачать extended.ini](presets/extended.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: extended.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=1
CaptureAllCommands=0
IncludeRawPayload=0
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=1
Diplomacy=1
Deployment=1
AirNavy=1
Movement=1
BattleOrders=1
Network=0
AIInternal=0
Interface=0
Other=1

[commands]
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
CSelectEventOptionCommand=0
```

</details>

### Основной с ИИ

Как основной, но распознанные команды ИИ тоже сохраняются. Внутренние классы ИИ отдельно не включаются.

[Скачать with-ai.ini](presets/with-ai.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: with-ai.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=0
CaptureAllCommands=0
IncludeRawPayload=0
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=0
Diplomacy=0
Deployment=1
AirNavy=0
Movement=1
BattleOrders=0
Network=0
AIInternal=0
Interface=0
Other=0

[commands]
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
CSelectEventOptionCommand=0
```

</details>

### Диагностика

Все категории и источники, raw-данные, полный JSON. Для исследования пропусков.

[Скачать diagnostic.ini](presets/diagnostic.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: diagnostic.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=0
SkipEngineAICommands=0
CaptureAllCommands=1
IncludeRawPayload=1
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=0
MaxFileMB=16
CompressRotated=1
GroupMovementBursts=0
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=1
Diplomacy=1
Deployment=1
AirNavy=1
Movement=1
BattleOrders=1
Network=1
AIInternal=1
Interface=1
Other=1

[commands]
```

</details>

### Авторский

Текущие настройки автора с явным включением семи ключевых команд. OnlyKnownPlayers=1 сохранён.

[Скачать author-current.ini](presets/author-current.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: author-current.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=1
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=1
CaptureAllCommands=1
IncludeRawPayload=0
OnlyKnownPlayers=1
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=1
Diplomacy=1
Deployment=1
AirNavy=1
Movement=1
BattleOrders=1
Network=0
AIInternal=0
Interface=1
Other=1

[commands]
CSelectEventOptionCommand=0
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
```

</details>

### Пауза

Основной профиль с Enabled=0. Для паузы своего конфига достаточно изменить только Enabled.

[Скачать paused.ini](presets/paused.ini)

<details>
<summary>Полный INI</summary>

```ini
; HOI4 MP Audit 0.1: paused.ini
; Full configuration. Copy as mp_audit.ini next to hoi4.exe.

[audit]
Enabled=0
TrackCommandOrigins=1
SkipEmptyUnknownCommands=1
SkipEngineAICommands=1
CaptureAllCommands=0
IncludeRawPayload=0
OnlyKnownPlayers=0
LogDirectory=mp_audit_logs

[storage]
CompactJSON=1
MaxFileMB=4
CompressRotated=1
GroupMovementBursts=1
MovementBurstWindowMs=50

[tracking]
Units=1
Equipment=1
Production=1
Theaters=1
Construction=1
Templates=1
Politics=0
Diplomacy=0
Deployment=1
AirNavy=0
Movement=1
BattleOrders=0
Network=0
AIInternal=0
Interface=0
Other=0

[commands]
CStockpiledEquipmentDeleteCommand=1
CDeleteUnitCommand=1
CMoveCommand=1
CMassMoveCommand=1
CCancelMovementCommand=1
CMassCancelMovementCommand=1
CStrategicRedeploymentCommand=1
CSelectEventOptionCommand=0
```

</details>

