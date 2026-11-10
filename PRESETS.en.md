# HOI4 MP Audit presets for reviewing core actions

[Русский](PRESETS.md) | [English](PRESETS.en.md)

These profiles focus on stockpile equipment/unit deletion and movement changes/cancellation. “Stockpile” here means stored equipment. Demolishing buildings or supply facilities uses different commands, some classified under Construction.

## Core commands

| Class | Observation |
|---|---|
| `CStockpiledEquipmentDeleteCommand` | Stockpile equipment deletion |
| `CDeleteUnitCommand` | Unit deletion/disbanding |
| `CMoveCommand` | Movement |
| `CMassMoveCommand` | Mass movement |
| `CCancelMovementCommand` | Movement cancellation |
| `CMassCancelMovementCommand` | Mass movement cancellation |
| `CStrategicRedeploymentCommand` | Strategic redeployment |

Ordinary active profiles explicitly enable these classes in [commands]. Turning off Movement alone will not exclude their explicit entries; change the relevant class entry to disable it. Sender/source filters still apply. Diagnostics selects every category. The paused profile records no new gameplay commands.

These records do not independently prove a successful action or intentional griefing. Mass movement parameters are not specifically decoded yet: available information is retained, but unit names and destinations are not guaranteed.

## Choose a profile

| Profile | File | Behavior |
|---|---|---|
| [Core actions](presets/core-actions.ini) | `core-actions.ini` | Only the seven key classes: stockpile equipment/unit deletion, individual/mass movement and cancellation, and strategic redeployment. |
| [Standard session](presets/balanced.ini) | `balanced.ini` | Core actions plus production, theaters, construction, templates and deployment. Politics, air missions and interface traffic are off. |
| [Extended review](presets/extended.ini) | `extended.ini` | Core actions and all gameplay categories, including battle orders, politics, diplomacy and aviation. Network service traffic and interface categories are off. |
| [Standard with AI](presets/with-ai.ini) | `with-ai.ini` | The standard profile with recognized AI retained. Internal AI classes are not separately enabled. |
| [Diagnostics](presets/diagnostic.ini) | `diagnostic.ini` | All categories and sources, raw bytes and full JSON. Intended for investigating missing or unexpected records. |
| [Author's profile](presets/author-current.ini) | `author-current.ini` | The author configuration with seven explicit core class selections. OnlyKnownPlayers=1 is retained. |
| [Paused](presets/paused.ini) | `paused.ini` | Standard profile with Enabled=0. To pause your own existing profile, change only Enabled instead. |

**Start with balanced.ini.** Use core-actions.ini for the smallest selection covering only the seven core command types.

## Apply a profile

1. Save a backup of your current mp_audit.ini.
2. Copy the selected INI next to hoi4.exe and name it mp_audit.ini.
3. Check LogDirectory; each profile inherits it from its corresponding base configuration.
4. Most switches reload in about two seconds. Changing LogDirectory or TrackCommandOrigins requires restarting the game.

A profile replaces the whole configuration, including custom exceptions. Downloading it does not automatically alter the active game INI. See [SETTINGS.en.md](SETTINGS.en.md) for individual options.

## Sources and possible omissions

- Ordinary profiles use OnlyKnownPlayers=0 so useful commands are not rejected merely because no participant nickname was matched.
- The author's profile retains OnlyKnownPlayers=1. Unmatched-sender commands can be omitted even when their class is enabled. This is not human verification.
- SkipEngineAICommands=1 omits confirmed engine_ai only; unknown sources are not guessed to be AI. Diagnostics and the with-AI profile retain recognized AI.
- SkipEmptyUnknownCommands=1 excludes empty diagnostics only. The diagnostic profile retains them.
- Deletions are never packed. Storage grouping currently covers CMoveCommand, CCancelMovementCommand and CStrategicRedeploymentCommand only. Mass classes are recorded separately; affected unit counts are not calculated. A series does not prove one click.
- Gzip compresses completed rotated parts without losing their data. Commands omitted by recording filters cannot be recovered later.

## Author's profile

This is based on the author's game INI. Other choices are retained, including OnlyKnownPlayers=1, Movement/BattleOrders/Interface=1 and CSelectEventOptionCommand=0. Only the seven explicit core class selections were added. Other filters can still omit a selected command.

## Complete configurations

Download a file or expand a block and copy its complete contents. Keep option names and filenames unchanged in either documentation language.

### Core actions

Only the seven key classes: stockpile equipment/unit deletion, individual/mass movement and cancellation, and strategic redeployment.

[Download core-actions.ini](presets/core-actions.ini)

<details>
<summary>Show complete INI</summary>

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

### Standard session

Core actions plus production, theaters, construction, templates and deployment. Politics, air missions and interface traffic are off.

[Download balanced.ini](presets/balanced.ini)

<details>
<summary>Show complete INI</summary>

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

### Extended review

Core actions and all gameplay categories, including battle orders, politics, diplomacy and aviation. Network service traffic and interface categories are off.

[Download extended.ini](presets/extended.ini)

<details>
<summary>Show complete INI</summary>

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

### Standard with AI

The standard profile with recognized AI retained. Internal AI classes are not separately enabled.

[Download with-ai.ini](presets/with-ai.ini)

<details>
<summary>Show complete INI</summary>

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

### Diagnostics

All categories and sources, raw bytes and full JSON. Intended for investigating missing or unexpected records.

[Download diagnostic.ini](presets/diagnostic.ini)

<details>
<summary>Show complete INI</summary>

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

### Author's profile

The author configuration with seven explicit core class selections. OnlyKnownPlayers=1 is retained.

[Download author-current.ini](presets/author-current.ini)

<details>
<summary>Show complete INI</summary>

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

### Paused

Standard profile with Enabled=0. To pause your own existing profile, change only Enabled instead.

[Download paused.ini](presets/paused.ini)

<details>
<summary>Show complete INI</summary>

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

