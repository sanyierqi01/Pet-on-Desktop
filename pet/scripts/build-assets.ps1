[CmdletBinding()]
param(
    [string]$Source,
    [string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    Add-Type -AssemblyName System.Drawing.Common
}
catch {
    Add-Type -AssemblyName System.Drawing
}

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = Join-Path $root 'assets\portrait-source.jpg'
}
if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $OutFile = Join-Path $root 'assets\head-cutout.png'
}

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$outputDirectory = Split-Path -Parent $OutFile
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$sourceBitmap = [System.Drawing.Bitmap]::FromFile($sourcePath)
try {
    # The supplied portrait is 534 x 800. This crop keeps the face, hair,
    # ears, and neck while removing most of the crossed-arm composition.
    $cropRectangle = [System.Drawing.Rectangle]::new(174, 28, 202, 230)
    $cutout = [System.Drawing.Bitmap]::new(
        $cropRectangle.Width,
        $cropRectangle.Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )

    try {
        $graphics = [System.Drawing.Graphics]::FromImage($cutout)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $destination = [System.Drawing.Rectangle]::new(0, 0, $cutout.Width, $cutout.Height)
            $graphics.DrawImage(
                $sourceBitmap,
                $destination,
                $cropRectangle,
                [System.Drawing.GraphicsUnit]::Pixel
            )
        }
        finally {
            $graphics.Dispose()
        }

        # A hand-fit silhouette mask avoids colour-keying the light studio
        # background, which would otherwise erase highlights on the face.
        $mask = [System.Drawing.Bitmap]::new(
            $cutout.Width,
            $cutout.Height,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        $maskGraphics = [System.Drawing.Graphics]::FromImage($mask)
        $maskPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $maskBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        try {
            $maskGraphics.Clear([System.Drawing.Color]::Transparent)
            $maskGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $maskPath.StartFigure()
            $maskPath.AddBezier(95, 27, 124, 26, 139, 49, 141, 76)
            $maskPath.AddBezier(145, 76, 147, 110, 137, 149, 121, 181)
            $maskPath.AddBezier(121, 181, 113, 200, 110, 216, 116, 229)
            $maskPath.AddLine(116, 229, 81, 229)
            $maskPath.AddBezier(81, 229, 83, 213, 74, 194, 62, 175)
            $maskPath.AddBezier(62, 175, 45, 145, 35, 108, 38, 75)
            $maskPath.AddBezier(38, 75, 39, 49, 67, 27, 95, 27)
            $maskPath.CloseFigure()
            $maskGraphics.FillPath($maskBrush, $maskPath)
        }
        finally {
            $maskBrush.Dispose()
            $maskPath.Dispose()
            $maskGraphics.Dispose()
        }

        try {
            for ($y = 0; $y -lt $cutout.Height; $y++) {
                for ($x = 0; $x -lt $cutout.Width; $x++) {
                    $pixel = $cutout.GetPixel($x, $y)
                    $alpha = $mask.GetPixel($x, $y).R
                    if ($y -lt 62) {
                        $maximum = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
                        $minimum = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
                        if (($maximum - $minimum) -lt 34 -and $maximum -gt 178) {
                            $alpha = 0
                        }
                    }
                    $color = [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B)
                    $cutout.SetPixel($x, $y, $color)
                }
            }
        }
        finally {
            $mask.Dispose()
        }

        $cutout.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $cutout.Dispose()
    }
}
finally {
    $sourceBitmap.Dispose()
}

Write-Output $OutFile
