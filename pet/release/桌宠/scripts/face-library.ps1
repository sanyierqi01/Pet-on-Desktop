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
        [System.Windows.Media.Imaging.BitmapSource]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $width = 202
    $height = 230
    $visual = [System.Windows.Media.DrawingVisual]::new()
    $context = $visual.RenderOpen()
    $maskGeometry = [System.Windows.Media.Geometry]::Parse(
        'M94.94,27.6 C125.24,25.3 140.39,46.7 142.41,76 ' +
        'C146.46,96.8 137.36,149.5 121.2,181.7 ' +
        'C113.12,200 111.1,216.2 115.14,230 ' +
        'L80.8,230 C82.82,213.2 74.74,195.5 62.62,175 ' +
        'C45.45,145 34.34,108 38.38,75 ' +
        'C39.39,49 67.67,27.6 94.94,27.6 Z'
    )
    $maskGeometry.Freeze()

    $drawing = [System.Windows.Media.DrawingGroup]::new()
    $drawingContext = $drawing.Open()
    $drawingContext.DrawGeometry(
        [System.Windows.Media.Brushes]::White,
        $null,
        $maskGeometry
    )
    $drawingContext.Close()

    $maskBrush = [System.Windows.Media.DrawingBrush]::new($drawing)
    $maskBrush.Viewbox = [System.Windows.Rect]::new(0, 0, $width, $height)
    $maskBrush.ViewboxUnits = [System.Windows.Media.BrushMappingMode]::Absolute
    $maskBrush.Viewport = [System.Windows.Rect]::new(0, 0, $width, $height)
    $maskBrush.ViewportUnits = [System.Windows.Media.BrushMappingMode]::Absolute

    $context.PushOpacityMask($maskBrush)
    $context.DrawImage(
        $Source,
        [System.Windows.Rect]::new(0, 0, $width, $height)
    )
    $context.Pop()
    $context.Close()

    $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
        $width,
        $height,
        96,
        96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $bitmap.Render($visual)

    $stream = [System.IO.File]::Create($Destination)
    try {
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $encoder.Save($stream)
    }
    finally {
        $stream.Dispose()
    }
}

function Import-FacePhoto {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,
        [string]$Name,
        [string]$Root = (Get-PetRoot)
    )

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

    $source = [System.Windows.Media.Imaging.BitmapImage]::new()
    $source.BeginInit()
    $source.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $source.UriSource = [System.Uri]::new((Resolve-Path -LiteralPath $ImagePath).Path)
    $source.EndInit()
    $source.Freeze()

    $targetAspect = 202.0 / 230.0
    $cropWidth = [Math]::Min(
        [double]$source.PixelWidth,
        [Math]::Max(96.0, [double]$face.width * 1.65)
    )
    $cropHeight = $cropWidth / $targetAspect
    if ($cropHeight -gt $source.PixelHeight) {
        $cropHeight = [double]$source.PixelHeight
        $cropWidth = $cropHeight * $targetAspect
    }

    $centerX = [double]$face.x + ([double]$face.width / 2)
    $centerY = [double]$face.y + ([double]$face.height * 0.32)
    $left = [Math]::Max(
        0.0,
        [Math]::Min(
            [double]$source.PixelWidth - $cropWidth,
            $centerX - ($cropWidth / 2)
        )
    )
    $top = [Math]::Max(
        0.0,
        [Math]::Min(
            [double]$source.PixelHeight - $cropHeight,
            $centerY - ($cropHeight / 2)
        )
    )
    $crop = [System.Windows.Media.Imaging.CroppedBitmap]::new(
        $source,
        [System.Windows.Int32Rect]::new(
            [int][Math]::Round($left),
            [int][Math]::Round($top),
            [int][Math]::Round($cropWidth),
            [int][Math]::Round($cropHeight)
        )
    )

    $id = 'face-' + [Guid]::NewGuid().ToString('N')
    $fileName = $id + '.png'
    $destination = Join-Path $paths.Directory $fileName
    Add-FaceMask -Source $crop -Destination $destination

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
