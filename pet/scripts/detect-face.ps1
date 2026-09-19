[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime

[void][Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
[void][Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType = WindowsRuntime]
[void][Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
[void][Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
[void][Windows.Media.FaceAnalysis.FaceDetector, Windows.Media.FaceAnalysis, ContentType = WindowsRuntime]

$asTaskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object {
        $_.Name -eq 'AsTask' -and
        $_.IsGenericMethod -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    } |
    Select-Object -First 1

if ($null -eq $asTaskMethod) {
    throw 'The Windows Runtime async bridge is unavailable.'
}

function Wait-WinRtResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Operation,
        [Parameter(Mandatory = $true)]
        [Type]$ResultType
    )

    $asyncType = [Windows.Foundation.IAsyncOperation``1].MakeGenericType($ResultType)
    $typedOperation = $Operation -as $asyncType
    if ($null -ne $typedOperation) {
        $status = $typedOperation.Status
        while ($status.ToString() -eq 'Started') {
            Start-Sleep -Milliseconds 10
            $status = $typedOperation.Status
        }
        if ($status.ToString() -ne 'Completed') {
            throw "The Windows Runtime operation ended with status $status."
        }
        return $typedOperation.GetResults()
    }

    $task = $asTaskMethod.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.Wait()
    return $task.Result
}

$fullPath = (Resolve-Path -LiteralPath $ImagePath).Path
$file = Wait-WinRtResult `
    -Operation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($fullPath)) `
    -ResultType ([Windows.Storage.StorageFile])

$stream = $null
$bitmap = $null
try {
    $stream = Wait-WinRtResult `
        -Operation ($file.OpenReadAsync()) `
        -ResultType ([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
    $decoder = Wait-WinRtResult `
        -Operation ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) `
        -ResultType ([Windows.Graphics.Imaging.BitmapDecoder])

    $bitmap = Wait-WinRtResult `
        -Operation ($decoder.GetSoftwareBitmapAsync(
            [Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8,
            [Windows.Graphics.Imaging.BitmapAlphaMode]::Premultiplied
        )) `
        -ResultType ([Windows.Graphics.Imaging.SoftwareBitmap])

    $detector = Wait-WinRtResult `
        -Operation ([Windows.Media.FaceAnalysis.FaceDetector]::CreateAsync()) `
        -ResultType ([Windows.Media.FaceAnalysis.FaceDetector])
    $detectedFaces = Wait-WinRtResult `
        -Operation ($detector.DetectFacesAsync($bitmap)) `
        -ResultType ([System.Collections.Generic.IList[Windows.Media.FaceAnalysis.DetectedFace]])

    $faces = @(
        foreach ($face in $detectedFaces) {
            [pscustomobject]@{
                x = [int]$face.FaceBox.X
                y = [int]$face.FaceBox.Y
                width = [int]$face.FaceBox.Width
                height = [int]$face.FaceBox.Height
            }
        }
    )

    [pscustomobject]@{
        success = $true
        imageWidth = [int]$decoder.PixelWidth
        imageHeight = [int]$decoder.PixelHeight
        faces = $faces
    } | ConvertTo-Json -Compress -Depth 5
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
    if ($null -ne $stream) {
        $stream.Dispose()
    }
}
