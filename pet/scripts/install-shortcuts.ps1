[CmdletBinding()]
param(
    [switch]$Startup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$executable = Join-Path $root '桌面宠物.exe'
$icon = Join-Path $root 'assets\pet.ico'

if (-not (Test-Path -LiteralPath $executable)) {
    throw '桌面宠物.exe does not exist. Run scripts\build-launcher.ps1 first.'
}

$shell = New-Object -ComObject WScript.Shell
$locations = @(
    [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory),
    (Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)) '桌宠')
)

if ($Startup) {
    $locations += [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup)
}

foreach ($directory in $locations) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $shortcutPath = Join-Path $directory '桌宠.lnk'
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $executable
    $shortcut.WorkingDirectory = $root
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = '自动爬行的桌面宠物'
    $shortcut.WindowStyle = 1
    $shortcut.Save()
    Write-Output $shortcutPath
}
