[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $root 'release'
$packageDirectory = Join-Path $releaseRoot '桌宠'
$archivePath = Join-Path $releaseRoot '桌宠-便携版.zip'

if (Test-Path -LiteralPath $packageDirectory) {
    $resolvedPackage = (Resolve-Path -LiteralPath $packageDirectory).Path
    $expectedPrefix = (Resolve-Path -LiteralPath $releaseRoot).Path
    if (-not $resolvedPackage.StartsWith($expectedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clear unexpected package path: $resolvedPackage"
    }
    Remove-Item -LiteralPath $resolvedPackage -Recurse -Force
}
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

New-Item -ItemType Directory -Force -Path $packageDirectory | Out-Null

$files = @(
    '桌面宠物.exe',
    'desktop-pet.ps1',
    'face-manager.ps1',
    '创建快捷方式.cmd',
    'README.md',
    '更新日志.md'
)
foreach ($relativePath in $files) {
    Copy-Item `
        -LiteralPath (Join-Path $root $relativePath) `
        -Destination (Join-Path $packageDirectory $relativePath) `
        -Force
}

$directories = @(
    'assets',
    'scripts',
    'ui'
)
foreach ($relativePath in $directories) {
    $source = Join-Path $root $relativePath
    $destination = Join-Path $packageDirectory $relativePath
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
}

# Keep only runtime files in the shared copy.
Remove-Item -LiteralPath (Join-Path $packageDirectory 'scripts\build-assets.ps1') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $packageDirectory 'scripts\build-launcher.ps1') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $packageDirectory 'scripts\build-release.ps1') -Force -ErrorAction SilentlyContinue

Compress-Archive -Path $packageDirectory -DestinationPath $archivePath -CompressionLevel Optimal

$hash = Get-FileHash -LiteralPath $archivePath -Algorithm SHA256
[pscustomobject]@{
    Package = $packageDirectory
    Archive = $archivePath
    SizeMB = [Math]::Round((Get-Item -LiteralPath $archivePath).Length / 1MB, 2)
    SHA256 = $hash.Hash
} | Format-List
