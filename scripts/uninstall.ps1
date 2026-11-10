[CmdletBinding(SupportsShouldProcess = $true)]
param([Parameter(Mandatory = $true)][string]$GameDirectory)
$ErrorActionPreference = 'Stop'
$target = (Resolve-Path -LiteralPath $GameDirectory).Path.TrimEnd('\')
if (-not (Test-Path -LiteralPath (Join-Path $target 'hoi4.exe') -PathType Leaf)) { throw 'GameDirectory must contain hoi4.exe.' }
if (Get-Process -Name hoi4 -ErrorAction SilentlyContinue) { throw 'Close HOI4 before uninstalling the audit DLL.' }
$receiptPath = Join-Path $target '.mp_audit_install.json'
if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'No audit installation receipt. No files were removed.' }
$receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
if ($receipt.schema -ne 1 -or $receipt.product -ne 'east-showdown-mp-audit' -or -not [string]::Equals($receipt.game_directory, $target, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Audit receipt does not match this directory.' }
foreach ($entry in @($receipt.files)) { if ($entry.name -notin @('version.dll', 'mp_audit.ini') -or $entry.sha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'Invalid audit receipt entry.' } }
# Validate the DLL before deleting any files. Unknown DLLs always remain untouched.
$dllEntry = @($receipt.files | Where-Object { $_.name -eq 'version.dll' })
$dll = Join-Path $target 'version.dll'
if ((Test-Path -LiteralPath $dll) -and ($dllEntry.Count -ne 1 -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne $dllEntry[0].sha256)) { throw 'version.dll has changed since installation. It will not be removed.' }
if (-not $PSCmdlet.ShouldProcess($target, 'Remove owned audit DLL and unchanged owned configuration; preserve logs')) { return }
foreach ($entry in @($receipt.files)) {
    $path = Join-Path $target $entry.name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -eq $entry.sha256) { Remove-Item -LiteralPath $path; Write-Output "Removed $($entry.name)" }
    else { Write-Output "Preserved modified $($entry.name)" }
}
Remove-Item -LiteralPath $receiptPath
Write-Output 'Audit uninstall complete. Existing logs and modified configuration were preserved.'
