# HOI4 MP Audit

[Русский](README.md) | [English](README.en.md)

**A game-command log for reviewing Hearts of Iron IV multiplayer sessions.**

The logger records commands available on the host's computer, including unit and stockpile equipment deletion, production changes, theater operations and movement orders. Use the report to review the timeline and look up the sender of a command.

**Version: 0.1 · Windows x64 · installed on the host's computer**

## Features

- **Command history.** Track unit and stockpile equipment deletion, production lines, factory assignments, theaters and other command categories. The amount of decoded detail depends on the command type.
- **Configurable recording.** Enable categories or individual commands. Most settings reload during play, about two seconds after saving the INI.
- **Recognized AI filter.** Exclude commands whose AI origin has been established. An unknown source is not automatically treated as AI.
- **Movement series.** Nearby eligible movement commands can share one log entry while retaining their individual times, IDs and parameters.
- **Automatic compression.** The active log updates during play. By default, files rotate at approximately 4 MiB and completed parts are compressed with gzip.
- **Reports.** Searchable HTML, sender filtering and CSV export. Compressed logs can be read without extracting them manually.

Installation is intended for the host only; other players do not need to download the logger. End users do not need Python or development tools. Controlled multiplayer validation is still pending; see Compatibility below.

## Download and install

1. Download **`HOI4_MP_Audit_0.1.zip` from Releases**. GitHub's `Source code` archives contain repository files, not the ready-to-use DLL.
2. Close the game and extract the downloaded archive into a separate folder.
3. Copy **`version.dll` and `mp_audit.ini`** next to `hoi4.exe`.
4. Launch the game normally. The `mp_audit_logs` folder is created automatically.

```text
Hearts of Iron IV/
├── hoi4.exe
├── version.dll
├── mp_audit.ini
└── mp_audit_logs/
```

If `version.dll` already exists, use the installer below. It checks ownership and preserves your configuration; it refuses to replace another tool's DLL.

<details>
<summary>Install and uninstall using scripts</summary>

Open PowerShell in the extracted package folder. Replace the example game path with your own:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -GameDirectory "C:\Games\Hearts of Iron IV"
```

If you installed using this script, uninstall while the game is closed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1 -GameDirectory "C:\Games\Hearts of Iron IV"
```

Existing configuration is preserved during installation. Logs and modified settings are retained during removal. For a manual installation, close the game and remove the logger's `version.dll` that you added to the game folder; you can keep the configuration and logs.

</details>

## Find and view logs

Logs are stored in **`mp_audit_logs` next to `hoi4.exe`**. Each launch starts a new file. The active `.jsonl` is appended during play; completed rotated parts use `.jsonl.gz`.

Open PowerShell in the extracted package folder and create a report, using your log directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\report.ps1 -LogPath "C:\Games\Hearts of Iron IV\mp_audit_logs"
```

Open **`mp_audit_report.html`** in that directory with a browser. The default limit is up to 10,000 recent commands. You can also supply a single `.jsonl` or `.jsonl.gz` file.

The report shows sender names, observed command sources and available parameters. Expand a series in the command-count column to inspect its members. The count represents commands, not units, and a series is not proof of one click.

| Option | Purpose |
|---|---|
| `-Sender "Nickname"` | Keep the specified sender |
| `-ExcludeEngineAI` | Hide confirmed AI-origin commands |
| `-ExpandBatches` | Show individual commands instead of series |
| `-Csv` | Export CSV instead of HTML |
| `-MaxRows 20000` | Increase the number of displayed commands |

## Configure recording

Edit **`mp_audit.ini` in the game folder**. In `[tracking]`, `1` enables a category and `0` disables it.

| Setting | Category |
|---|---|
| `Units` | Units, including deletion |
| `Equipment` | Equipment and stockpiles |
| `Production` | Production |
| `Theaters` | Theaters |
| `Politics` | Events, research, focuses and other political commands |
| `Movement` | Movement and strategic redeployment |
| `BattleOrders` | Fronts and battle orders |

**Movement is enabled in the standard profile.** Stockpile equipment/unit deletion and individual/mass movement/cancellation commands are also explicitly enabled in `[commands]`. Enable battle orders separately with `BattleOrders=1`. See [PRESETS.en.md](PRESETS.en.md) for ready-to-use profiles.

To exclude a particular command, add its class to `[commands]`. For example, exclude event-option selection:

```ini
[commands]
CSelectEventOptionCommand=0
```

The recognized AI filter is enabled by default: **`SkipEngineAICommands=1`** in `[audit]`. Use `0` to record these commands. Filter counters do not produce periodic log rows.

See **[SETTINGS.en.md](SETTINGS.en.md)** for all options and **[command_catalog.csv](command_catalog.csv)** for exact class names. Replacing the DLL or changing the log directory or origin instrumentation requires a game restart.

## Interpret records

**A nickname identifies the sender endpoint, not a verified human author.** AI commands may use the host's machine as their sender. Unresolved sources remain unknown; one such record is not sufficient to accuse someone of griefing.

A record captures entry into command execution. Successful effects are not independently confirmed. Times refer to execution, not mouse clicks. Some objects are shown as internal IDs; unit/model names and quantities of destroyed equipment may be unavailable. The last records may be lost if the game exits abnormally.

## Compatibility

Supported build: **Operation Postern v1.19.4.2.2da5**, Windows x64. The exact EXE is checked automatically. Auditing is not enabled on unsupported builds; game updates require a compatibility review.

**0.1 is experimental.** Controlled multiplayer, hotjoin, desync behavior and unchanged checksum have not yet been verified for this release.
