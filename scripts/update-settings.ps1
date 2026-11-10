[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameDirectory,
    [string]$TemplatePath
)
$ErrorActionPreference = 'Stop'
$target = (Resolve-Path -LiteralPath $GameDirectory).Path.TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $target 'hoi4.exe') -PathType Leaf)) { throw 'GameDirectory must contain hoi4.exe.' }
if (-not $TemplatePath) { $TemplatePath = Join-Path $PSScriptRoot '..\mp_audit.ini' }
$defaults = [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $TemplatePath).Path)
$configuration = Join-Path $target 'mp_audit.ini'
function Parse-Ini([string[]]$Lines) {
    $sections = [ordered]@{}
    $current = $null
    foreach ($line in $Lines) {
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            $current = $Matches[1].Trim()
            if (-not $sections.Contains($current)) { $sections[$current] = [ordered]@{} }
        } elseif ($current -and $line -match '^\s*([^;#=][^=]*?)\s*=\s*(.*?)\s*$') {
            $sections[$current][$Matches[1].Trim()] = $Matches[2]
        }
    }
    return $sections
}
$merged = Parse-Ini $defaults
if (Test-Path -LiteralPath $configuration -PathType Leaf) {
    $previous = Parse-Ini ([IO.File]::ReadAllLines($configuration))
    foreach ($section in $previous.Keys) {
        if (-not $merged.Contains($section)) { $merged[$section] = [ordered]@{} }
        foreach ($key in $previous[$section].Keys) { $merged[$section][$key] = $previous[$section][$key] }
    }
    $backup = $configuration + '.before-0.1-' + [guid]::NewGuid().ToString('N') + '.bak'
    Copy-Item -LiteralPath $configuration -Destination $backup
    Write-Output "Configuration backup: $backup"
}
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('; MP Audit 0.1: switches reload live about every 2 seconds. Existing values preserved.')
$lines.Add('; [tracking]: category defaults. [commands]: exact class overrides (0/1).')
$lines.Add('; [storage]: CompactJSON, MaxFileMB, CompressRotated, GroupMovementBursts, MovementBurstWindowMs.')
$lines.Add('; [audit] SkipEngineAICommands=1 excludes confirmed engine_ai only; unknown sources are not guessed.')
$lines.Add('; [audit] SkipEmptyUnknownCommands: filter only unknown commands without sender/identity/target/details.')
foreach ($section in $merged.Keys) {
    $lines.Add(''); $lines.Add('[' + $section + ']')
    foreach ($key in $merged[$section].Keys) { $lines.Add($key + '=' + $merged[$section][$key]) }
}
$temporary = $configuration + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
try {
    # INI W APIs recognize UTF-16LE with BOM, including non-ASCII directory names.
    [IO.File]::WriteAllLines($temporary, $lines, [Text.Encoding]::Unicode)
    Move-Item -LiteralPath $temporary -Destination $configuration -Force
} finally {
    if (Test-Path -LiteralPath $temporary -PathType Leaf) { Remove-Item -LiteralPath $temporary }
}
Write-Output "Updated $configuration; preserved existing values and added missing switches."
