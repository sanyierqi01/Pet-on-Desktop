[CmdletBinding()]
param(
    [switch]$Startup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$application = [pscustomobject]@{
    Name = '桌宠'
    Executable = Join-Path $root '桌面宠物.exe'
    Description = '桌宠与人脸管理'
}
$icon = Join-Path $root 'assets\pet.ico'

if (-not (Test-Path -LiteralPath $application.Executable)) {
    throw "$($application.Executable) does not exist. Run scripts\build-launcher.ps1 first."
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
    $legacyShortcut = Join-Path $directory '人脸管理.lnk'
    if (Test-Path -LiteralPath $legacyShortcut) {
        Remove-Item -LiteralPath $legacyShortcut -Force
    }

    $shortcutPath = Join-Path $directory '桌宠.lnk'
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $application.Executable
    $shortcut.WorkingDirectory = $root
    $shortcut.IconLocation = "$icon,0"
    $shortcut.Description = $application.Description
    $shortcut.WindowStyle = 1
    $shortcut.Save()
    Write-Output $shortcutPath
}
