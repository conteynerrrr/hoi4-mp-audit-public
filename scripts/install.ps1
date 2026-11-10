[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$GameDirectory,
    [string]$PackageDirectory
)
$ErrorActionPreference = 'Stop'
if (-not $PackageDirectory) {
    $PackageDirectory = Join-Path $PSScriptRoot '..'
    if (-not (Test-Path -LiteralPath (Join-Path $PackageDirectory 'version.dll') -PathType Leaf)) { $PackageDirectory = Join-Path $PSScriptRoot '..\out' }
}
$target = (Resolve-Path -LiteralPath $GameDirectory).Path.TrimEnd('\')
$package = (Resolve-Path -LiteralPath $PackageDirectory).Path
if (-not (Test-Path -LiteralPath (Join-Path $target 'hoi4.exe') -PathType Leaf)) { throw 'GameDirectory must contain hoi4.exe.' }
if (Get-Process -Name hoi4 -ErrorAction SilentlyContinue) { throw 'Close HOI4 before installing the audit DLL.' }
$sourceDll = Join-Path $package 'version.dll'
if (-not (Test-Path -LiteralPath $sourceDll -PathType Leaf)) { throw "Package DLL not found: $sourceDll" }
$dll = Join-Path $target 'version.dll'
$config = Join-Path $target 'mp_audit.ini'
$receiptPath = Join-Path $target '.mp_audit_install.json'
$product = 'east-showdown-mp-audit'
$receipt = $null
if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
    $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    if ($receipt.product -ne $product -or $receipt.schema -ne 1 -or -not [string]::Equals($receipt.game_directory, $target, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Existing audit installation receipt is not recognized for this directory.' }
    foreach ($entry in @($receipt.files)) { if ($entry.name -notin @('version.dll', 'mp_audit.ini') -or $entry.sha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'Invalid audit receipt entry.' } }
}
if (Test-Path -LiteralPath $dll) {
    $owned = @($receipt.files | Where-Object { $_.name -eq 'version.dll' })
    if ($owned.Count -ne 1 -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne $owned[0].sha256) { throw 'An existing version.dll is not owned by this installer, or has changed. It will not be replaced.' }
}
if (-not $PSCmdlet.ShouldProcess($target, 'Install host MP audit version.dll and ownership receipt')) { return }
$sourceHash = (Get-FileHash -LiteralPath $sourceDll -Algorithm SHA256).Hash.ToLowerInvariant()
$id = [guid]::NewGuid().ToString('N')
$staged = Join-Path $target ".mp_audit.$id.dll.tmp"
$backup = Join-Path $target ".mp_audit.$id.rollback.tmp"
$stagedReceipt = Join-Path $target ".mp_audit.$id.receipt.tmp"
$configCreated = $false
$dllChanged = $false
$backupHash = $null
try {
    Copy-Item -LiteralPath $sourceDll -Destination $staged
    if ((Get-FileHash -LiteralPath $staged -Algorithm SHA256).Hash -ne $sourceHash) { throw 'Staged DLL hash does not match package.' }
    if (Test-Path -LiteralPath $dll -PathType Leaf) {
        $backupHash = (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
        Copy-Item -LiteralPath $dll -Destination $backup
        if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $backupHash) { throw 'Rollback copy hash mismatch.' }
    }
    Move-Item -LiteralPath $staged -Destination $dll -Force
    $dllChanged = $true
    $files = @([ordered]@{ name = 'version.dll'; sha256 = $sourceHash })
    $sourceConfig = Join-Path $package 'mp_audit.ini'
    if (-not (Test-Path -LiteralPath $config) -and (Test-Path -LiteralPath $sourceConfig -PathType Leaf)) {
        Copy-Item -LiteralPath $sourceConfig -Destination $config
        $configCreated = $true
        $files += [ordered]@{ name = 'mp_audit.ini'; sha256 = (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash.ToLowerInvariant() }
    } elseif ($receipt) {
        $previousConfig = @($receipt.files | Where-Object { $_.name -eq 'mp_audit.ini' })
        if ($previousConfig.Count -eq 1) { $files += [ordered]@{ name = 'mp_audit.ini'; sha256 = $previousConfig[0].sha256 } }
        Write-Output 'Existing mp_audit.ini preserved.'
    } elseif (Test-Path -LiteralPath $config) { Write-Output 'Existing mp_audit.ini preserved and not claimed by this installer.' }
    $next = [ordered]@{ schema = 1; product = $product; game_directory = $target; installed_utc = [DateTime]::UtcNow.ToString('o'); files = $files }
    $next | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stagedReceipt -Encoding utf8
    Move-Item -LiteralPath $stagedReceipt -Destination $receiptPath -Force
    Write-Output "Installed $dll"
    Write-Output 'Logs are written to mp_audit_logs unless mp_audit.ini overrides LogDirectory. MP checksum compatibility still requires the documented MP test.'
}
catch {
    # Roll back only bytes installed by this invocation; never overwrite a concurrent change.
    if ($dllChanged -and (Test-Path -LiteralPath $dll -PathType Leaf) -and (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -eq $sourceHash) {
        if ($backupHash -and (Test-Path -LiteralPath $backup -PathType Leaf) -and (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -eq $backupHash) { Move-Item -LiteralPath $backup -Destination $dll -Force }
        elseif (-not $backupHash) { Remove-Item -LiteralPath $dll }
    }
    if ($configCreated -and (Test-Path -LiteralPath $config -PathType Leaf) -and (Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath (Join-Path $package 'mp_audit.ini') -Algorithm SHA256).Hash) { Remove-Item -LiteralPath $config }
    throw
}
finally {
    foreach ($temporary in @($staged, $backup, $stagedReceipt)) { if (Test-Path -LiteralPath $temporary -PathType Leaf) { Remove-Item -LiteralPath $temporary } }
}
