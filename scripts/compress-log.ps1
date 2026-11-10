[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogPath,
    [string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $LogPath).Path
if (-not $OutputPath) { $OutputPath = $source + '.gz' }
$destination = [IO.Path]::GetFullPath($OutputPath)
if ([string]::Equals($source, $destination, [StringComparison]::OrdinalIgnoreCase)) { throw 'Source and archive must differ.' }
if (Test-Path -LiteralPath $destination) { throw 'Archive already exists; no files were changed.' }
$temporary = $destination + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
$inputFile = $null; $outputFile = $null; $gzip = $null
try {
    # Sharing Read only refuses an active writer. Never archive a changing live log.
    $inputFile = [IO.File]::Open($source, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $originalLength = $inputFile.Length
    $outputFile = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $gzip = [IO.Compression.GZipStream]::new($outputFile, [IO.Compression.CompressionLevel]::Optimal, $true)
    $inputFile.CopyTo($gzip)
    $gzip.Dispose(); $gzip = $null
    $outputFile.Flush($true); $outputFile.Dispose(); $outputFile = $null
    $inputFile.Dispose(); $inputFile = $null
    [IO.File]::Move($temporary, $destination)
    [pscustomobject]@{Archive=$destination;OriginalBytes=$originalLength;ArchiveBytes=(Get-Item -LiteralPath $destination).Length;OriginalPreserved=$true} | ConvertTo-Json
} finally {
    if ($gzip) { $gzip.Dispose() }
    if ($outputFile) { $outputFile.Dispose() }
    if ($inputFile) { $inputFile.Dispose() }
    if (Test-Path -LiteralPath $temporary -PathType Leaf) { Remove-Item -LiteralPath $temporary }
}
