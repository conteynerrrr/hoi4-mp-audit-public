# HOI4 MP Audit 0.1 settings

[Русский](SETTINGS.md) | [English](SETTINGS.en.md)

This guide explains what each option records, how filters interact and how to reduce log size. For complete ready-to-use configurations, see **[PRESETS.en.md](PRESETS.en.md)**. Installation and report instructions are in [README.en.md](README.en.md).

## 1. Edit the active configuration

The logger reads **`mp_audit.ini` next to `hoi4.exe`**. The file in the repository or extracted package is a template; editing that copy does not change an existing installation.

```text
Hearts of Iron IV/
├── hoi4.exe
├── version.dll
├── mp_audit.ini       # active configuration
└── mp_audit_logs/
```

- Use `1` and `0`, not `true` and `false`.
- Place keys in their correct section: `[audit]`, `[storage]`, `[tracking]` or `[commands]`.
- A line starting with `;` is a comment and has no effect.
- Keep one value per key; duplicate sections and keys make the configuration ambiguous.
- Back up your INI before replacing it. A complete preset also replaces your command exceptions and log path.

| Change | Takes effect |
|---|---|
| `Enabled`, filters, categories, `[commands]` | About two seconds after saving |
| Compression, part size, movement packing | After reload, for subsequent writing/rotation |
| `LogDirectory` | Next game launch |
| `TrackCommandOrigins` | Next game launch |
| `version.dll` itself | Replace while the game is closed, then relaunch |

Settings do not rewrite old records. `settings_reloaded` indicates that the file was reloaded. Commands already captured in the queue may still be written after a switch changes.

## 2. Quick reference

| Goal | Setting |
|---|---|
| Pause new command records | `[audit] Enabled=0`; restore `1` to resume |
| Exclude recognized AI | `[audit] TrackCommandOrigins=1` and `SkipEngineAICommands=1` |
| Retain commands without a matched sender | `[audit] OnlyKnownPlayers=0` |
| Require a matched sender | `[audit] OnlyKnownPlayers=1` |
| Select movement category | `[tracking] Movement=1` |
| Select fronts and battle orders | `[tracking] BattleOrders=1` |
| Exclude event-option selection | `[commands] CSelectEventOptionCommand=0` |
| Reduce redundant fields | `[storage] CompactJSON=1` |
| Compress completed parts | `[storage] CompressRotated=1` and a positive `MaxFileMB` |
| Pack eligible movement series | `[storage] GroupMovementBursts=1` |
| Inspect unexpected records or missing data | [Diagnostic preset](presets/diagnostic.ini) |

Defaults below refer to the supplied standard INI. Other presets and your own file may differ. The standard profile explicitly selects seven core deletion/movement classes in `[commands]`; see [PRESETS.en.md](PRESETS.en.md).

## 3. Main options: `[audit]`

### `Enabled`

**Template: `1`.** `1` permits recording of selected commands after the other filters. `0` pauses new game-command records. The DLL remains loaded; startup, configuration and error messages may still appear. Restore `1` to resume with your existing categories and exceptions.

### `TrackCommandOrigins`

**Template: `1`. Restart required.** Enables the discovered observation points for engine AI, the host interface and accepted network commands. With `0`, commands can still be recorded without those origin observations.

`origins_ready` reports successful installation; `origins_unavailable` means source information may remain unknown. Coverage is partial: the confirmed local-interface path currently covers air-mission assignment. Other interface actions may remain `unknown`.

This option does not prove a human author. Turning it off prevents the AI filter from removing commands whose source remains unresolved.

### `SkipEngineAICommands`

**Template: `1`.** With `1`, records labelled `origin_kind=engine_ai` are omitted. With `0`, they are retained if other filters allow them.

The filter uses observed origin, not class name, country, nickname or command rate. It does not classify `unknown` as AI. Unrecognized AI paths may therefore remain in the log. Keep `TrackCommandOrigins=1` for origin recognition.

If an older INI omits this key, the fallback is `0`, preserving AI recording. Ordinary presets set it explicitly. This affects logging only; game commands still execute.

**`AIInternal=0` is different:** that category selects certain internal AI classes. AI also uses normal gameplay classes, including air-mission commands. Source filtering handles recognized AI using those classes.

### `SkipEmptyUnknownCommands`

**Template: `1`.** Omits unknown commands that simultaneously lack a known execution context, matched sender, nonzero command/original ID, object, country, useful parameters, text, result or raw data. Set `0` to retain them for diagnostics.

A typical empty record has `machine_id=-1`, `command_identity=0`, `original_id=0`, and unknown origin/context, with no additional information.

This does not exclude every `unknown` record. Unknown commands with useful data can remain. However, `OnlyKnownPlayers=1` independently excludes commands without a matched participant.

There are no periodic filter-counter rows. Totals may be included in the existing shutdown record if the logger stops gracefully.

### `OnlyKnownPlayers`

**Template: `0`.** `0` does not reject a record merely because its sender was not matched. `1` requires matching the sender ID to a nickname in the current participant roster.

The historical name means “known senders.” It does not verify a person or replace the AI filter. AI may use the host's sender identity and pass this check, then be excluded by `SkipEngineAICommands`.

| Example | Meaning |
|---|---|
| Nickname present, source unknown | Sender matched; origin unresolved; the record may remain |
| Host nickname, source engine_ai | Recognized AI; the host nickname does not establish a manual action |
| No sender match, object ID present | Can remain with `0`; excluded with `1` |

Use `0` for a more complete review. `1` reduces unmatched-sender traffic but can discard useful commands too.

### `IncludeRawPayload`

**Template: `0`.** `1` copies up to 128 accessible bytes of the internal command object into `payload_hex`; `0` omits this copy.

These bytes are diagnostic data, not a complete network packet, a unit name or a full parameter decoder. They increase log size. Ordinary sessions generally use `0`.

### `CaptureAllCommands`

**Template: `0`.** A compatibility default for categories not explicitly present in the INI. `0` uses normal category defaults; `1` enables otherwise unspecified categories.

Explicit `[tracking]` and `[commands]` values take priority. `CaptureAllCommands=1` does not override `Network=0`. If every category is already listed, this key has little effect on category selection.

Use the [diagnostic preset](presets/diagnostic.ini) to explicitly enable every category.

### `LogDirectory`

**Template: `mp_audit_logs`. Restart required.** A relative path is resolved from the DLL/game folder:

```ini
[audit]
LogDirectory=mp_audit_logs
```

An absolute path moves logs elsewhere:

```ini
[audit]
LogDirectory=D:\HOI4_Logs
```

Create parent directories beforehand for a nested path. Check this key when applying a complete preset: the preset also replaces your previous log directory.

## 4. Categories: `[tracking]`

`1` selects a category; `0` disables it. Categories classify command types, not their human authors. Explicit per-class choices can override category selection.

| Key | Commands covered | Template |
|---|---|---:|
| `Units` | Units, armies, leaders, deletion of units/ships/air wings | 1 |
| `Equipment` | Equipment, variants, stockpiles and stockpile equipment deletion | 1 |
| `Production` | Production lines, factory assignments and priorities | 1 |
| `Theaters` | Theater assignment, naming, ordering and disbanding | 1 |
| `Construction` | Construction, buildings, conversion, railways and supply | 1 |
| `Templates` | Division templates | 1 |
| `Politics` | Focuses, research, decisions, events, doctrines and advisors | 0 |
| `Diplomacy` | Diplomacy, trade, lend-lease, factions and market | 0 |
| `Deployment` | Deployment and training queues | 1 |
| `AirNavy` | Aircraft, air missions, fleets, naval missions and raids | 0 |
| `Movement` | Movement, strategic redeployment and cancellation | 1 |
| `BattleOrders` | Fronts, defense, offensive and other battle orders | 0 |
| `Network` | Ping, ticks, checksums, synchronization and file transfer | 0 |
| `AIInternal` | Internal classes prefixed CAi… / CAI… | 0 |
| `Interface` | Interface commands, pinned regions, chat and highlighting | 0 |
| `Other` | Types not classified above | 0 |

For the exact category of each class, use [command_catalog.csv](command_catalog.csv). Gameplay descriptions do not always map intuitively to internal class names. The 456-type catalog is not a guarantee that every interface action or client-local change is observable.

The standard profile includes movement and explicitly selects the core movement classes. Enable `BattleOrders` separately if needed.

## 5. Per-command choices: `[commands]`

Use the exact `command_class` from the log or catalog. `1` selects a class regardless of category; `0` excludes it regardless of category.

```ini
[tracking]
Units=1
Movement=0
Politics=1

[commands]
CMoveCommand=1
CSelectEventOptionCommand=0
```

Here the movement category is off, but CMoveCommand is selected. Politics is on, but event-option selection is excluded. Other explicit exceptions already present in your INI continue to apply.

| Goal | Entry |
|---|---|
| Select unit deletion | `CDeleteUnitCommand=1` |
| Select stockpile equipment deletion | `CStockpiledEquipmentDeleteCommand=1` |
| Select production-line removal | `CRemoveProductionLineCommand=1` |
| Exclude air-mission assignment | `CStratAirSetMissionCommand=0` |
| Exclude event-option selection | `CSelectEventOptionCommand=0` |

Delete or comment out an entry with `;` to return that class to its category's behavior. Class choices do not override Enabled, sender, AI or empty-record filters.

### Selection order

1. `Enabled` permits recording.
2. An explicit class entry selects/excludes the type; otherwise its category is used.
3. Unspecified categories inherit the compatibility/default behavior of CaptureAllCommands.
4. OnlyKnownPlayers may require a matched sender.
5. SkipEngineAICommands and SkipEmptyUnknownCommands omit matching records.
6. Remaining records are written; eligible movement can be packed.

For example, `CDeleteUnitCommand=1` selects the class, but an instance labelled engine_ai is still omitted when SkipEngineAICommands=1.

## 6. Storage: `[storage]`

| Key | Template | Range |
|---|---:|---|
| `CompactJSON` | 1 | 0 / 1 |
| `MaxFileMB` | 4 | 0–64; 0 disables size rotation |
| `CompressRotated` | 1 | 0 / 1 |
| `GroupMovementBursts` | 1 | 0 / 1 |
| `MovementBurstWindowMs` | 50 | 1–500 ms |

### `CompactJSON`

`1` removes redundant, empty and repeated fields while retaining UTC and available command information. `0` writes full JSON with diagnostic fields including QPC/FILETIME. It changes representation, not selected command types or whether raw copying is enabled.

### `MaxFileMB`

`4` starts a new part at approximately 4 MiB. JSON lines are never split; exact part sizes can differ slightly. Values above 64 are capped at 64.

`0` disables size-based rotation, so normal rotation will not produce completed parts for CompressRotated. This is a per-part limit, not a total-history quota. Old sessions are not deleted automatically.

### `CompressRotated`

`1` compresses a completed part after rotating to the next one. Compression runs on the logging worker, not the game-command thread. The format is standard `.jsonl.gz`.

The active file stays plain. The final part may remain plain after the game exits because automatic compression is tied to rotation. Source data is preserved if archival fails.

`0` keeps parts as text; existing archives are not extracted. This release has no INI option for xz or gzip compression level.

### `GroupMovementBursts`

`1` packs eligible consecutive CMoveCommand, CCancelMovementCommand and CStrategicRedeploymentCommand records. They must share the sender, type, tickstamp, source, ordinary queue context and common metadata. AI, replay, ambiguous-source and deletion records are not packed. Maximum size is 128 commands.

Each member retains its time, IDs, object, parameters and raw payload; only common fields are shared. Mass movement/cancellation classes are recorded separately and are not supported by this storage grouping yet.

`0` keeps separate command records in the file. The report can still visually group nearby movement; use `-ExpandBatches` to show individual rows. This option does not enable movement recording itself. Explicit category/class selection is still required.

### `MovementBurstWindowMs`

Default: 50 ms from the first command in a series. The window does not extend indefinitely with each new command. Values below 1 are clamped to 1; values above 500 to 500.

A smaller window creates more separate series. A larger one can combine distinct quick orders. A series does not establish one click, and the member count is not a unit count. UTC reflects execution, not mouse input.

## 7. Report options are separate from the INI

Pass these to `scripts/report.ps1`; do not put them in mp_audit.ini.

| Option | Purpose |
|---|---|
| `-LogPath "path"` | A JSONL, JSONL.GZ or log directory |
| `-OutputPath "path"` | Custom HTML/CSV destination |
| `-Csv` | CSV instead of HTML |
| `-Sender "Nickname"` | Sender nickname filter, not verified authorship |
| `-ExcludeEngineAI` | Hide already recorded confirmed AI-origin commands |
| `-IncludeEmptyUnknown` | Include empty unknown records that exist in the source |
| `-ExpandBatches` | Show individual commands instead of series |
| `-MovementBurstWindowMs 50` | Visual grouping window, 1–500 ms |
| `-MaxRows 20000` | Recent-record limit; default 10000, range 1–200000 |

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\report.ps1 -LogPath "C:\Games\Hearts of Iron IV\mp_audit_logs" -ExcludeEngineAI -ExpandBatches
```

Reports preserve source files. HTML expands series details. Grouped CSV contains the first member's parameters plus count, time range and all IDs; add -ExpandBatches for each member's parameters.

The report reads ordinary schemas 1/2/3 and batch schema 4. It cannot recover commands omitted during recording. If a directory contains both a plain part and its gzip copy, it uses the plain file to avoid duplication.

## 8. Troubleshooting

**CaptureAllCommands=1 did not enable everything.** Check explicit categories, class choices and other filters. The compatibility default does not override them.

**Unknown commands remain with SkipEngineAICommands=1.** Their source was not established; the logger does not guess that they are AI.

**Does the host's nickname prove a click?** No. AI may use the same sender endpoint. Human authorship is not independently verified.

**Why use OnlyKnownPlayers=0?** To preserve potentially useful records without a roster match. With 1, those records can be lost even if their class is selected.

**Why are there still many rows with grouping enabled?** Only three movement types qualify; different senders/types/ticks/common metadata/windows/order separate series. Deletions remain separate.

**Old records did not disappear after changing a filter.** INI changes affect future recording. Use -ExcludeEngineAI to hide previously recorded AI in reports.

**The edited INI has no effect.** Check that it is named mp_audit.ini and is next to the actual hoi4.exe being launched.

**How do I apply a complete profile?** Follow [PRESETS.en.md](PRESETS.en.md). Save your original INI before replacement. The [author profile](presets/author-current.ini) includes the author's preferences and explicit core command choices.
