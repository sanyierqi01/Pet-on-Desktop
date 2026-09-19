Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PetRoot {
    return Split-Path -Parent $PSScriptRoot
}

function Get-FaceLibraryPaths {
    param([string]$Root = (Get-PetRoot))

    $directory = Join-Path $Root 'assets\faces'
    [pscustomobject]@{
        Root = $Root
        Directory = $directory
        Metadata = Join-Path $directory 'library.json'
        DefaultImage = Join-Path $directory 'default.png'
        BuiltInImage = Join-Path $Root 'assets\head-cutout.png'
    }
}

function Save-FaceLibrary {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Library,
        [Parameter(Mandatory = $true)]
        [string]$MetadataPath
    )

    $json = $Library | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText(
        $MetadataPath,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Initialize-FaceLibrary {
    param([string]$Root = (Get-PetRoot))

    $paths = Get-FaceLibraryPaths -Root $Root
    New-Item -ItemType Directory -Force -Path $paths.Directory | Out-Null

    if (-not (Test-Path -LiteralPath $paths.DefaultImage)) {
        if (-not (Test-Path -LiteralPath $paths.BuiltInImage)) {
            throw 'The built-in face image is missing.'
        }
        Copy-Item -LiteralPath $paths.BuiltInImage -Destination $paths.DefaultImage
    }

    if (-not (Test-Path -LiteralPath $paths.Metadata)) {
        $now = (Get-Date).ToUniversalTime().ToString('o')
        $library = [pscustomobject]@{
            version = 1
            currentId = 'default'
            faces = @(
                [pscustomobject]@{
                    id = 'default'
                    name = '默认人脸'
                    file = 'default.png'
                    isDefault = $true
                    createdAt = $now
                }
            )
        }
        Save-FaceLibrary -Library $library -MetadataPath $paths.Metadata
    }

    return Read-FaceLibrary -Root $Root
}

function Read-FaceLibrary {
    param([string]$Root = (Get-PetRoot))

    $paths = Get-FaceLibraryPaths -Root $Root
    if (-not (Test-Path -LiteralPath $paths.Metadata)) {
        return Initialize-FaceLibrary -Root $Root
    }

    return Get-Content -LiteralPath $paths.Metadata -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-CurrentFacePath {
    param([string]$Root = (Get-PetRoot))

    $paths = Get-FaceLibraryPaths -Root $Root
    $library = Initialize-FaceLibrary -Root $Root
    $current = $library.faces |
        Where-Object { $_.id -eq $library.currentId } |
        Select-Object -First 1

    if ($null -eq $current) {
        $current = $library.faces |
            Where-Object { $_.isDefault } |
            Select-Object -First 1
    }

    if ($null -eq $current) {
        return $paths.BuiltInImage
    }

    $facePath = Join-Path $paths.Directory $current.file
    if (Test-Path -LiteralPath $facePath) {
        return $facePath
    }
    return $paths.BuiltInImage
}

function Add-FaceMask {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Bitmap]$Bitmap
    )

    $width = $Bitmap.Width
    $height = $Bitmap.Height
    $mask = [System.Drawing.Bitmap]::new(
        $width,
        $height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($mask)
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $path.StartFigure()
        $path.AddBezier(
            $width * 0.47, $height * 0.12,
            $width * 0.62, $height * 0.11,
            $width * 0.69, $height * 0.21,
            $width * 0.70, $height * 0.33
        )
        $path.AddBezier(
            $width * 0.70, $height * 0.33,
            $width * 0.73, $height * 0.48,
            $width * 0.68, $height * 0.65,
            $width * 0.60, $height * 0.79
        )
        $path.AddBezier(
            $width * 0.60, $height * 0.79,
            $width * 0.56, $height * 0.87,
            $width * 0.55, $height * 0.94,
            $width * 0.57, $height
        )
        $path.AddLine($width * 0.57, $height, $width * 0.40, $height)
        $path.AddBezier(
            $width * 0.40, $height,
            $width * 0.41, $height * 0.93,
            $width * 0.37, $height * 0.85,
            $width * 0.31, $height * 0.76
        )
        $path.AddBezier(
            $width * 0.31, $height * 0.76,
            $width * 0.22, $height * 0.63,
            $width * 0.17, $height * 0.47,
            $width * 0.19, $height * 0.33
        )
        $path.AddBezier(
            $width * 0.19, $height * 0.33,
            $width * 0.19, $height * 0.19,
            $width * 0.34, $height * 0.12,
            $width * 0.47, $height * 0.12
        )
        $path.CloseFigure()
        $graphics.FillPath($brush, $path)
    }
    finally {
        $brush.Dispose()
        $path.Dispose()
        $graphics.Dispose()
    }

    try {
        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $pixel = $Bitmap.GetPixel($x, $y)
                $alpha = $mask.GetPixel($x, $y).R
                $Bitmap.SetPixel(
                    $x,
                    $y,
                    [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B)
                )
            }
        }
    }
    finally {
        $mask.Dispose()
    }
}

function Import-FacePhoto {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,
        [string]$Name,
        [string]$Root = (Get-PetRoot)
    )

    Add-Type -AssemblyName System.Drawing.Common -ErrorAction SilentlyContinue
    if (-not ('System.Drawing.Bitmap' -as [type])) {
        Add-Type -AssemblyName System.Drawing
    }

    $paths = Get-FaceLibraryPaths -Root $Root
    $detectorPath = Join-Path $Root 'scripts\detect-face.ps1'
    $powerShellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $detectorOutput = & $powerShellPath `
        -NoLogo `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -STA `
        -File $detectorPath `
        -ImagePath $ImagePath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($detectorOutput | Out-String)
    }

    $detection = ($detectorOutput | Out-String) | ConvertFrom-Json
    if (-not $detection.success -or $detection.faces.Count -eq 0) {
        throw '没有在照片中检测到人脸。'
    }

    $face = $detection.faces |
        Sort-Object { $_.width * $_.height } -Descending |
        Select-Object -First 1

    $source = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $ImagePath).Path)
    try {
        $targetAspect = 202.0 / 230.0
        $cropWidth = [Math]::Min(
            [double]$source.Width,
            [Math]::Max(96.0, [double]$face.width * 1.65)
        )
        $cropHeight = $cropWidth / $targetAspect
        if ($cropHeight -gt $source.Height) {
            $cropHeight = [double]$source.Height
            $cropWidth = $cropHeight * $targetAspect
        }

        $centerX = [double]$face.x + ([double]$face.width / 2)
        $centerY = [double]$face.y + ([double]$face.height * 0.32)
        $left = [Math]::Max(0.0, [Math]::Min([double]$source.Width - $cropWidth, $centerX - ($cropWidth / 2)))
        $top = [Math]::Max(0.0, [Math]::Min([double]$source.Height - $cropHeight, $centerY - ($cropHeight / 2)))

        $cutout = [System.Drawing.Bitmap]::new(
            202,
            230,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($cutout)
            try {
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage(
                    $source,
                    [System.Drawing.Rectangle]::new(0, 0, 202, 230),
                    [System.Drawing.Rectangle]::new(
                        [int][Math]::Round($left),
                        [int][Math]::Round($top),
                        [int][Math]::Round($cropWidth),
                        [int][Math]::Round($cropHeight)
                    ),
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            }
            finally {
                $graphics.Dispose()
            }

            Add-FaceMask -Bitmap $cutout

            $id = 'face-' + [Guid]::NewGuid().ToString('N')
            $fileName = $id + '.png'
            $destination = Join-Path $paths.Directory $fileName
            $cutout.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $cutout.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }

    $library = Initialize-FaceLibrary -Root $Root
    $uploadedCount = @($library.faces | Where-Object { -not $_.isDefault }).Count + 1
    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = "人脸 $uploadedCount"
    }

    $newFace = [pscustomobject]@{
        id = $id
        name = $Name
        file = $fileName
        isDefault = $false
        createdAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    $library.faces = @($library.faces) + $newFace
    $library.currentId = $id
    Save-FaceLibrary -Library $library -MetadataPath $paths.Metadata

    return $newFace
}

function Set-CurrentFace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FaceId,
        [string]$Root = (Get-PetRoot)
    )

    $library = Initialize-FaceLibrary -Root $Root
    if (-not ($library.faces | Where-Object { $_.id -eq $FaceId })) {
        throw "Face entry '$FaceId' was not found."
    }

    $paths = Get-FaceLibraryPaths -Root $Root
    $library.currentId = $FaceId
    Save-FaceLibrary -Library $library -MetadataPath $paths.Metadata
}

function Remove-Face {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FaceId,
        [string]$Root = (Get-PetRoot)
    )

    $library = Initialize-FaceLibrary -Root $Root
    $face = $library.faces |
        Where-Object { $_.id -eq $FaceId } |
        Select-Object -First 1
    if ($null -eq $face) {
        throw "Face entry '$FaceId' was not found."
    }
    if ($face.isDefault) {
        throw '默认人脸不能删除。'
    }

    $paths = Get-FaceLibraryPaths -Root $Root
    $remaining = @($library.faces | Where-Object { $_.id -ne $FaceId })
    $library.faces = $remaining
    if ($library.currentId -eq $FaceId) {
        $library.currentId = 'default'
    }
    Save-FaceLibrary -Library $library -MetadataPath $paths.Metadata

    $facePath = Join-Path $paths.Directory $face.file
    if (Test-Path -LiteralPath $facePath) {
        Remove-Item -LiteralPath $facePath -Force
    }
}
