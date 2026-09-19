[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'launcher\DesktopPetLauncher.cs'
$previewPath = Join-Path $root 'assets\pet-preview.png'
$iconPath = Join-Path $root 'assets\pet.ico'
$outputPath = Join-Path $root '桌面宠物.exe'

$compilerCandidates = @(
    (Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($null -eq $compiler) {
    throw 'The .NET Framework C# compiler was not found.'
}

if (-not (Test-Path -LiteralPath $previewPath)) {
    & (Join-Path $root 'desktop-pet.ps1') -ExportPreview | Out-Null
}

Add-Type -AssemblyName System.Drawing.Common
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class PetIconNativeMethods
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool DestroyIcon(IntPtr handle);
}
'@

$preview = [System.Drawing.Bitmap]::FromFile($previewPath)
$iconBitmap = [System.Drawing.Bitmap]::new(
    64,
    64,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
$graphics = [System.Drawing.Graphics]::FromImage($iconBitmap)
$iconHandle = [IntPtr]::Zero
try {
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage(
        $preview,
        [System.Drawing.Rectangle]::new(0, 0, 64, 64),
        [System.Drawing.Rectangle]::new(25, 0, 250, 235),
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $iconHandle = $iconBitmap.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
    try {
        $iconStream = [System.IO.File]::Create($iconPath)
        try {
            $icon.Save($iconStream)
        }
        finally {
            $iconStream.Dispose()
        }
    }
    finally {
        $icon.Dispose()
    }
}
finally {
    if ($iconHandle -ne [IntPtr]::Zero) {
        [PetIconNativeMethods]::DestroyIcon($iconHandle) | Out-Null
    }
    $graphics.Dispose()
    $iconBitmap.Dispose()
    $preview.Dispose()
}

if ($Force -or -not (Test-Path -LiteralPath $outputPath)) {
    & $compiler `
        /nologo `
        /target:winexe `
        /optimize+ `
        /codepage:65001 `
        "/win32icon:$iconPath" `
        "/out:$outputPath" `
        $sourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "Launcher compilation failed with exit code $LASTEXITCODE."
    }
}

Get-Item -LiteralPath $outputPath, $iconPath |
    Select-Object FullName, Length, LastWriteTime
