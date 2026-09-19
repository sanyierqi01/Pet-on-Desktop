[CmdletBinding()]
param(
    [switch]$ExportPreview,
    [string]$PreviewPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Speech

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$headPath = Join-Path $root 'assets\head-cutout.png'
$sourcePath = Join-Path $root 'assets\portrait-source.jpg'

if (-not (Test-Path -LiteralPath $headPath)) {
    & (Join-Path $root 'scripts\build-assets.ps1') -Source $sourcePath -OutFile $headPath | Out-Null
}
if ([string]::IsNullOrWhiteSpace($PreviewPath)) {
    $PreviewPath = Join-Path $root 'assets\pet-preview.png'
}

function New-FrozenBrush {
    param([string]$Hex)

    $brush = [System.Windows.Media.SolidColorBrush]::new(
        [System.Windows.Media.ColorConverter]::ConvertFromString($Hex)
    )
    $brush.Freeze()
    return $brush
}

function New-FrozenPen {
    param(
        [string]$Hex,
        [double]$Thickness
    )

    $pen = [System.Windows.Media.Pen]::new((New-FrozenBrush $Hex), $Thickness)
    $pen.StartLineCap = [System.Windows.Media.PenLineCap]::Round
    $pen.EndLineCap = [System.Windows.Media.PenLineCap]::Round
    $pen.LineJoin = [System.Windows.Media.PenLineJoin]::Round
    $pen.Freeze()
    return $pen
}

function New-FrozenGeometry {
    param([string]$PathData)

    $geometry = [System.Windows.Media.Geometry]::Parse($PathData)
    $geometry.Freeze()
    return $geometry
}

function New-FrozenCurveGeometry {
    param(
        [System.Windows.Point]$Start,
        [System.Windows.Point]$Control,
        [System.Windows.Point]$End
    )

    $geometry = [System.Windows.Media.StreamGeometry]::new()
    $context = $geometry.Open()
    $context.BeginFigure($Start, $false, $false)
    $context.BezierTo($Control, $Control, $End, $true, $false)
    $context.Close()
    $geometry.Freeze()
    return $geometry
}

$colors = @{
    Ink = '#263042'
    InkSoft = '#52647B'
    Shirt = '#B8C9E2'
    ShirtLight = '#D8E2F0'
    ShirtStripe = '#F4F7FB'
    Jeans = '#24344F'
    JeansLight = '#3A4F72'
    JeansDark = '#17243A'
    Skin = '#D7A486'
    SkinLight = '#E8B99B'
    Shoe = '#17202C'
    ShoeLight = '#344257'
    Shadow = '#5A3348'
    Blush = '#E58F8B'
    Sweat = '#75B9DA'
}

$brushes = @{}
foreach ($entry in $colors.GetEnumerator()) {
    $brushes[$entry.Key] = New-FrozenBrush $entry.Value
}

$shadowBrush = [System.Windows.Media.SolidColorBrush]::new(
    [System.Windows.Media.Color]::FromArgb(48, 71, 49, 64)
)
$shadowBrush.Freeze()
$groundBrush = [System.Windows.Media.SolidColorBrush]::new(
    [System.Windows.Media.Color]::FromArgb(35, 28, 48, 66)
)
$groundBrush.Freeze()
$blushBrush = [System.Windows.Media.SolidColorBrush]::new(
    [System.Windows.Media.Color]::FromArgb(105, 229, 128, 128)
)
$blushBrush.Freeze()

$headImage = [System.Windows.Media.Imaging.BitmapImage]::new()
$headImage.BeginInit()
$headImage.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$headImage.UriSource = [System.Uri]::new($headPath)
$headImage.EndInit()
$headImage.Freeze()

function Add-PetDrawing {
    param(
        [System.Windows.Media.DrawingContext]$Context,
        [double]$Phase,
        [double]$Reaction,
        [double]$Facing = 1.0,
        [double]$Moving = 0.0,
        [double]$Tired = 0.0
    )

    $breath = [Math]::Sin($Phase) * 1.35
    $bounce = -$Reaction * 15
    $cycleAngle = $Phase * 0.72
    $crawlA = [Math]::Sin($cycleAngle) * $Moving
    $crawlB = -$crawlA
    $liftA = [Math]::Max(0.0, [Math]::Sin($cycleAngle + [Math]::PI / 2)) * $Moving
    $liftB = [Math]::Max(0.0, [Math]::Sin($cycleAngle - [Math]::PI / 2)) * $Moving
    $headBob = $breath - ($Reaction * 2.5) + ([Math]::Cos($cycleAngle * 2) * $Moving * 2.2) + ($Tired * 5.5)
    $bodyShiftX = ([Math]::Sin($Phase * 0.53) * 1.15) - ($crawlA * 5.2)
    $bodyShiftY = $breath + $bounce + ([Math]::Sin($cycleAngle * 2) * $Moving * 0.8) + ($Tired * 2.5)
    $bodyPitch = $crawlA * 0.8

    $Context.PushTransform(
        [System.Windows.Media.TranslateTransform]::new($bodyShiftX, $bodyShiftY)
    )
    $Context.PushTransform(
        [System.Windows.Media.RotateTransform]::new($bodyPitch, 150, 120)
    )
    if ($Facing -lt 0) {
        $Context.PushTransform([System.Windows.Media.ScaleTransform]::new(-1, 1, 150, 120))
    }

    $Context.DrawEllipse($shadowBrush, $null, [System.Windows.Point]::new(169, 205), 111, 13)
    $Context.DrawEllipse($groundBrush, $null, [System.Windows.Point]::new(65, 191), 24, 6)
    $Context.DrawEllipse($groundBrush, $null, [System.Windows.Point]::new(132, 191), 24, 6)

    # The far legs alternate with the near arm in a diagonal gait.
    $farHip = [System.Windows.Point]::new(169, 146)
    $farKnee = [System.Windows.Point]::new(193 + ($crawlA * 7), 161 - ($liftA * 4))
    $farFoot = [System.Windows.Point]::new(250 - ($crawlA * 14), 186 - ($liftA * 8))
    $farThighCurve = New-FrozenCurveGeometry `
        -Start $farHip `
        -Control ([System.Windows.Point]::new(181 + ($crawlA * 4), 149 + ($liftA * 3))) `
        -End $farKnee
    $farCalfCurve = New-FrozenCurveGeometry `
        -Start $farKnee `
        -Control ([System.Windows.Point]::new(220 - ($crawlA * 9), 168 - ($liftA * 5))) `
        -End $farFoot
    $Context.DrawGeometry($null, (New-FrozenPen $colors.Jeans 26), $farThighCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansDark 3.2), $farThighCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansLight 18), $farCalfCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansDark 2.8), $farCalfCurve)
    $Context.DrawEllipse($brushes.Jeans, (New-FrozenPen $colors.JeansDark 2), $farKnee, 11, 8)

    # The near leg sits a little lower and moves in the opposite phase.
    $nearHip = [System.Windows.Point]::new(158, 152)
    $nearKnee = [System.Windows.Point]::new(177 - ($crawlB * 7), 176 - ($liftB * 4))
    $nearFoot = [System.Windows.Point]::new(228 - ($crawlB * 14), 198 - ($liftB * 8))
    $nearThighCurve = New-FrozenCurveGeometry `
        -Start $nearHip `
        -Control ([System.Windows.Point]::new(168 - ($crawlB * 4), 160 + ($liftB * 3))) `
        -End $nearKnee
    $nearCalfCurve = New-FrozenCurveGeometry `
        -Start $nearKnee `
        -Control ([System.Windows.Point]::new(202 - ($crawlB * 9), 186 - ($liftB * 5))) `
        -End $nearFoot
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansLight 27), $nearThighCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansDark 3.2), $nearThighCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.Jeans 19), $nearCalfCurve)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.JeansDark 2.8), $nearCalfCurve)
    $Context.DrawEllipse($brushes.JeansLight, (New-FrozenPen $colors.JeansDark 2), $nearKnee, 11, 8)

    # Far arm and near arm move in opposite phases.
    $farShoulder = [System.Windows.Point]::new(101, 108)
    $farElbow = [System.Windows.Point]::new(76 - ($crawlB * 9), 139 - ($liftB * 5))
    $farHand = [System.Windows.Point]::new(64 - ($crawlB * 17), 185 - ($liftB * 9))
    $farUpperArm = New-FrozenCurveGeometry `
        -Start $farShoulder `
        -Control ([System.Windows.Point]::new(
            ($farShoulder.X + $farElbow.X) / 2,
            ($farShoulder.Y + $farElbow.Y) / 2
        )) `
        -End $farElbow
    $farForearm = New-FrozenCurveGeometry `
        -Start $farElbow `
        -Control ([System.Windows.Point]::new(
            ($farElbow.X + $farHand.X) / 2 - 2,
            ($farElbow.Y + $farHand.Y) / 2
        )) `
        -End $farHand
    $Context.DrawGeometry($null, (New-FrozenPen $colors.Shirt 22), $farUpperArm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 3.1), $farUpperArm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.Shirt 19), $farForearm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 2.8), $farForearm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.ShirtStripe 1.1), $farUpperArm)

    # Horizontal shirt torso connects the raised shoulders to the kneeling hips.
    $torso = New-FrozenGeometry 'M90,101 C116,89 143,101 172,124 C193,140 195,155 188,167 C158,174 128,164 101,143 C85,131 82,112 90,101 Z'
    $Context.DrawGeometry($brushes.Shirt, (New-FrozenPen $colors.InkSoft 2), $torso)

    $Context.PushClip($torso)
    for ($x = 94; $x -le 185; $x += 9) {
        $Context.DrawLine(
            (New-FrozenPen $colors.ShirtStripe 0.8),
            [System.Windows.Point]::new($x, 94),
            [System.Windows.Point]::new($x - 10, 176)
        )
    }
    $Context.Pop()

    # Shirt opening, collar, and a few visible buttons.
    $Context.DrawLine(
        (New-FrozenPen $colors.InkSoft 1.2),
        [System.Windows.Point]::new(111, 104),
        [System.Windows.Point]::new(124, 153)
    )
    $leftCollar = New-FrozenGeometry 'M96,105 L113,107 L103,121 Z'
    $rightCollar = New-FrozenGeometry 'M119,102 L110,112 L128,116 Z'
    $Context.DrawGeometry($brushes.ShirtLight, (New-FrozenPen $colors.InkSoft 1), $leftCollar)
    $Context.DrawGeometry($brushes.ShirtLight, (New-FrozenPen $colors.InkSoft 1), $rightCollar)
    foreach ($y in @(119, 134, 148)) {
        $Context.DrawEllipse($brushes.ShirtLight, $null, [System.Windows.Point]::new(120 + (($y - 119) * 0.2), $y), 1.7, 1.7)
    }

    # Jeans waistband and back pocket anchor the shirt over the folded legs.
    $hips = New-FrozenGeometry 'M162,143 C181,137 198,145 205,159 L198,176 L158,166 C156,158 157,149 162,143 Z'
    $Context.DrawGeometry($brushes.Jeans, (New-FrozenPen $colors.JeansDark 1.8), $hips)
    $Context.DrawLine(
        (New-FrozenPen $colors.JeansDark 1.8),
        [System.Windows.Point]::new(160, 149),
        [System.Windows.Point]::new(199, 163)
    )
    $Context.DrawLine(
        (New-FrozenPen $colors.JeansDark 1.2),
        [System.Windows.Point]::new(180, 150),
        [System.Windows.Point]::new(193, 155)
    )

    # The source photo remains visible as the face. It is scaled down and
    # overlapped with the illustrated neck and collar.
    $Context.DrawEllipse($brushes.Skin, $null, [System.Windows.Point]::new(101, 118), 19, 21)
    $headRect = [System.Windows.Rect]::new(39 - ($crawlA * 2.5), 17 + $headBob, 106, 134)
    $Context.DrawImage($headImage, $headRect)

    if ($Tired -gt 0.01) {
        $faceOffsetX = -($crawlA * 2.5)
        $leftEye = [System.Windows.Point]::new(73 + $faceOffsetX, 78 + $headBob)
        $rightEye = [System.Windows.Point]::new(114 + $faceOffsetX, 78 + $headBob)
        $leftLid = New-FrozenCurveGeometry `
            -Start ([System.Windows.Point]::new($leftEye.X - 10, $leftEye.Y)) `
            -Control ([System.Windows.Point]::new($leftEye.X, $leftEye.Y - 6)) `
            -End ([System.Windows.Point]::new($leftEye.X + 10, $leftEye.Y + 1))
        $rightLid = New-FrozenCurveGeometry `
            -Start ([System.Windows.Point]::new($rightEye.X - 10, $rightEye.Y)) `
            -Control ([System.Windows.Point]::new($rightEye.X, $rightEye.Y - 6)) `
            -End ([System.Windows.Point]::new($rightEye.X + 10, $rightEye.Y + 1))
        $leftBrow = New-FrozenCurveGeometry `
            -Start ([System.Windows.Point]::new($leftEye.X - 10, $leftEye.Y - 10)) `
            -Control ([System.Windows.Point]::new($leftEye.X, $leftEye.Y - 12)) `
            -End ([System.Windows.Point]::new($leftEye.X + 10, $leftEye.Y - 7))
        $rightBrow = New-FrozenCurveGeometry `
            -Start ([System.Windows.Point]::new($rightEye.X - 10, $rightEye.Y - 7)) `
            -Control ([System.Windows.Point]::new($rightEye.X, $rightEye.Y - 12)) `
            -End ([System.Windows.Point]::new($rightEye.X + 10, $rightEye.Y - 10))
        $tiredMouth = New-FrozenCurveGeometry `
            -Start ([System.Windows.Point]::new(92 + $faceOffsetX, 111 + $headBob)) `
            -Control ([System.Windows.Point]::new(103 + $faceOffsetX, 106 + $headBob)) `
            -End ([System.Windows.Point]::new(114 + $faceOffsetX, 111 + $headBob))

        $Context.PushOpacity($Tired * 0.9)
        $Context.DrawEllipse($brushes.Skin, $null, $leftEye, 10, 6)
        $Context.DrawEllipse($brushes.Skin, $null, $rightEye, 10, 6)
        $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 2.6), $leftLid)
        $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 2.6), $rightLid)
        $Context.DrawGeometry($null, (New-FrozenPen $colors.Ink 2.1), $leftBrow)
        $Context.DrawGeometry($null, (New-FrozenPen $colors.Ink 2.1), $rightBrow)
        $Context.DrawGeometry($null, (New-FrozenPen $colors.Ink 2.2), $tiredMouth)
        $Context.DrawEllipse(
            $brushes.Sweat,
            (New-FrozenPen '#4E9BBD' 1.1),
            [System.Windows.Point]::new(132 + $faceOffsetX, 72 + $headBob),
            4,
            7
        )
        $Context.Pop()
    }

    # Near arm stays in front of the torso and reaches forward on the
    # opposite beat from the far arm.
    $nearShoulder = [System.Windows.Point]::new(122, 106)
    $nearElbow = [System.Windows.Point]::new(148 + ($crawlA * 9), 140 - ($liftA * 5))
    $nearHand = [System.Windows.Point]::new(133 + ($crawlA * 17), 181 - ($liftA * 9))
    $nearUpperArm = New-FrozenCurveGeometry `
        -Start $nearShoulder `
        -Control ([System.Windows.Point]::new(
            ($nearShoulder.X + $nearElbow.X) / 2,
            ($nearShoulder.Y + $nearElbow.Y) / 2
        )) `
        -End $nearElbow
    $nearForearm = New-FrozenCurveGeometry `
        -Start $nearElbow `
        -Control ([System.Windows.Point]::new(
            ($nearElbow.X + $nearHand.X) / 2 + 2,
            ($nearElbow.Y + $nearHand.Y) / 2
        )) `
        -End $nearHand
    $Context.DrawGeometry($null, (New-FrozenPen $colors.ShirtLight 23), $nearUpperArm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 3.1), $nearUpperArm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.ShirtLight 20), $nearForearm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.InkSoft 2.8), $nearForearm)
    $Context.DrawGeometry($null, (New-FrozenPen $colors.ShirtStripe 1.2), $nearUpperArm)

    # Hands and individual fingers remain visible during reach and recovery.
    $Context.DrawEllipse($brushes.Skin, (New-FrozenPen $colors.InkSoft 1.2), $farHand, 18, 9)
    $Context.DrawEllipse($brushes.SkinLight, (New-FrozenPen $colors.InkSoft 1.2), $nearHand, 18, 9)
    foreach ($offset in @(-6, 0, 6)) {
        $Context.DrawLine(
            (New-FrozenPen $colors.Skin 2.2),
            [System.Windows.Point]::new($farHand.X + $offset, $farHand.Y + 2),
            [System.Windows.Point]::new($farHand.X + $offset + 3, $farHand.Y + 11)
        )
        $Context.DrawLine(
            (New-FrozenPen $colors.Skin 2.2),
            [System.Windows.Point]::new($nearHand.X + $offset, $nearHand.Y + 2),
            [System.Windows.Point]::new($nearHand.X + $offset + 3, $nearHand.Y + 11)
        )
    }

    # Shoes stay attached to the moving knees and swing with the calves.
    $Context.DrawEllipse($brushes.Shoe, (New-FrozenPen $colors.Ink 1.6), $farFoot, 17, 9)
    $Context.DrawEllipse($brushes.ShoeLight, (New-FrozenPen $colors.Ink 1.6), $nearFoot, 17, 9)
    $Context.DrawLine(
        (New-FrozenPen $colors.ShoeLight 2),
        [System.Windows.Point]::new($farFoot.X - 8, $farFoot.Y - 3),
        [System.Windows.Point]::new($farFoot.X + 10, $farFoot.Y + 1)
    )

    # A tiny blush pulse gives the click response a friendly read.
    if ($Reaction -gt 0.05) {
        $Context.DrawEllipse($blushBrush, $null, [System.Windows.Point]::new(78, 91 + $headBob), 7, 3.3)
        $Context.DrawEllipse($blushBrush, $null, [System.Windows.Point]::new(120, 91 + $headBob), 7, 3.3)
    }

    if ($Facing -lt 0) {
        $Context.Pop()
    }
    $Context.Pop()
    $Context.Pop()
}

function Export-PetPreview {
    param([string]$Path)

    $visual = [System.Windows.Media.DrawingVisual]::new()
    $context = $visual.RenderOpen()
    Add-PetDrawing -Context $context -Phase 0.65 -Reaction 0
    $context.Close()

    $bitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
        300,
        240,
        96,
        96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $bitmap.Render($visual)

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $stream = [System.IO.File]::Create($Path)
    try {
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
        $encoder.Save($stream)
    }
    finally {
        $stream.Dispose()
    }

    $tiredPath = Join-Path $directory 'pet-tired-preview.png'
    $tiredVisual = [System.Windows.Media.DrawingVisual]::new()
    $tiredContext = $tiredVisual.RenderOpen()
    Add-PetDrawing -Context $tiredContext -Phase 0.65 -Reaction 0 -Tired 1
    $tiredContext.Close()
    $tiredBitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
        300,
        240,
        96,
        96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $tiredBitmap.Render($tiredVisual)
    $tiredStream = [System.IO.File]::Create($tiredPath)
    try {
        $tiredEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $tiredEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($tiredBitmap))
        $tiredEncoder.Save($tiredStream)
    }
    finally {
        $tiredStream.Dispose()
    }

    $motionPath = Join-Path $directory 'pet-motion-preview.png'
    $motionVisual = [System.Windows.Media.DrawingVisual]::new()
    $motionContext = $motionVisual.RenderOpen()
    $motionPhases = @()
    for ($index = 0; $index -lt 16; $index++) {
        $motionPhases += $index * 0.5454
    }
    for ($index = 0; $index -lt $motionPhases.Count; $index++) {
        $column = $index % 4
        $row = [Math]::Floor($index / 4)
        $motionContext.PushTransform(
            [System.Windows.Media.TranslateTransform]::new($column * 300, $row * 240)
        )
        Add-PetDrawing `
            -Context $motionContext `
            -Phase $motionPhases[$index] `
            -Reaction 0 `
            -Facing 1 `
            -Moving 1
        $motionContext.Pop()
    }
    $motionContext.Close()

    $motionBitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
        1200,
        960,
        96,
        96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $motionBitmap.Render($motionVisual)
    $motionStream = [System.IO.File]::Create($motionPath)
    try {
        $motionEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $motionEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($motionBitmap))
        $motionEncoder.Save($motionStream)
    }
    finally {
        $motionStream.Dispose()
    }

    Write-Output $Path
    Write-Output $tiredPath
    Write-Output $motionPath
}

if ($ExportPreview) {
    Export-PetPreview -Path $PreviewPath
    return
}

$visual = [System.Windows.Media.DrawingVisual]::new()
$window = [System.Windows.Window]::new()
$window.Title = 'Mian Bao Desktop Pet'
$window.Width = 300
$window.Height = 240
$window.WindowStyle = [System.Windows.WindowStyle]::None
$window.ResizeMode = [System.Windows.ResizeMode]::NoResize
$window.AllowsTransparency = $true
$window.Background = [System.Windows.Media.Brushes]::Transparent
$window.ShowInTaskbar = $false
$window.Topmost = $true

$hostVisual = [System.Windows.Media.VisualBrush]::new($visual)
$hostVisual.Stretch = [System.Windows.Media.Stretch]::None
$hostVisual.AlignmentX = [System.Windows.Media.AlignmentX]::Left
$hostVisual.AlignmentY = [System.Windows.Media.AlignmentY]::Top

$surface = [System.Windows.Controls.Border]::new()
$surface.Background = $hostVisual
$surface.ToolTip = '拖动我；点一下会跳；右键打开菜单'
$window.Content = $surface

$workArea = [System.Windows.SystemParameters]::WorkArea
$window.Left = [Math]::Max(0, $workArea.Right - $window.Width - 18)
$window.Top = [Math]::Max(0, $workArea.Bottom - $window.Height - 10)

$script:phase = 0.0
$script:reaction = 0.0
$script:lastRender = [DateTime]::UtcNow
$script:dragging = $false
$script:dragMoved = $false
$script:dragStartScreen = [System.Windows.Point]::new(0, 0)
$script:dragStartWindow = [System.Windows.Point]::new(0, 0)
$script:autoCrawl = $true
$script:facing = 1.0
$script:moving = 0.0
$script:turnTimes = [System.Collections.Generic.Queue[DateTime]]::new()
$script:tiredUntil = [DateTime]::MinValue
$script:lastTiredSpeech = [DateTime]::MinValue
$script:tiredExpression = 0.0

$script:speech = $null
try {
    $speechCandidate = [System.Speech.Synthesis.SpeechSynthesizer]::new()
    $chineseVoices = @(
        $speechCandidate.GetInstalledVoices() |
            Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -eq 'zh-CN' }
    )
    $preferredVoice = $chineseVoices |
        Where-Object { $_.VoiceInfo.Name -like '*Kangkang*' } |
        Select-Object -First 1
    if ($null -eq $preferredVoice -and $chineseVoices.Count -gt 0) {
        $preferredVoice = $chineseVoices[0]
    }
    if ($null -ne $preferredVoice) {
        $speechCandidate.SelectVoice($preferredVoice.VoiceInfo.Name)
    }
    $speechCandidate.Rate = 0
    $speechCandidate.Volume = 100
    $script:speech = $speechCandidate
}
catch {
    if ($null -ne $speechCandidate) {
        $speechCandidate.Dispose()
    }
    $script:speech = $null
}

function Update-PetMotion {
    param([double]$Elapsed)

    $script:moving = [Math]::Max(0.0, $script:moving - ($Elapsed * 2.4))
    if (
        -not $script:autoCrawl -or
        $script:dragging -or
        $window.ContextMenu.IsOpen
    ) {
        return
    }

    $now = [DateTime]::UtcNow
    if ($now -lt $script:tiredUntil) {
        return
    }

    $cursor = [System.Windows.Forms.Cursor]::Position
    $cursorInWindow = $window.PointFromScreen(
        [System.Windows.Point]::new($cursor.X, $cursor.Y)
    )
    $deltaX = $cursorInWindow.X - ($window.Width / 2)
    $deltaY = $cursorInWindow.Y - ($window.Height * 0.62)

    if ([Math]::Abs($deltaX) -gt 22) {
        $desiredFacing = $script:facing
        if ($deltaX -gt 0) {
            $desiredFacing = -1.0
        }
        else {
            $desiredFacing = 1.0
        }

        if ($desiredFacing -ne $script:facing) {
            $script:facing = $desiredFacing
            [void]$script:turnTimes.Enqueue($now)

            while (
                $script:turnTimes.Count -gt 0 -and
                ($now - $script:turnTimes.Peek()).TotalSeconds -gt 4
            ) {
                [void]$script:turnTimes.Dequeue()
            }

            if ($script:turnTimes.Count -ge 4) {
                if (($now - $script:lastTiredSpeech).TotalSeconds -ge 8) {
                    Invoke-PetSpeech -Text '宝宝，我累了'
                    $script:lastTiredSpeech = $now
                }
                $script:tiredUntil = $now.AddSeconds(3)
                $script:tiredExpression = 1.0
                $script:turnTimes.Clear()
                $script:moving = 0.0
                return
            }
        }
    }

    $distance = [Math]::Sqrt(($deltaX * $deltaX) + ($deltaY * $deltaY))
    if ($distance -le 72) {
        return
    }

    $speed = 58.0
    $travel = [Math]::Min($speed * $Elapsed, $distance - 68)
    if ($travel -le 0) {
        return
    }

    $stepX = ($deltaX / $distance) * $travel
    $stepY = ($deltaY / $distance) * $travel

    $minLeft = $workArea.Left + 4
    $maxLeft = $workArea.Right - $window.Width - 4
    $minTop = $workArea.Top + 4
    $maxTop = $workArea.Bottom - $window.Height - 4

    $window.Left = [Math]::Max($minLeft, [Math]::Min($maxLeft, $window.Left + $stepX))
    $window.Top = [Math]::Max($minTop, [Math]::Min($maxTop, $window.Top + $stepY))
    $script:moving = 1.0
}

function Render-Pet {
    $now = [DateTime]::UtcNow
    $elapsed = [Math]::Min(0.08, [Math]::Max(0.001, ($now - $script:lastRender).TotalSeconds))
    $script:lastRender = $now
    Update-PetMotion -Elapsed $elapsed
    $script:phase += $elapsed * (2.15 + ($script:moving * 6.0))
    $script:reaction *= [Math]::Pow(0.08, $elapsed)
    $tiredTarget = if ($now -lt $script:tiredUntil) { 1.0 } else { 0.0 }
    $tiredBlend = [Math]::Min(1.0, $elapsed * 4.5)
    $script:tiredExpression += ($tiredTarget - $script:tiredExpression) * $tiredBlend

    $context = $visual.RenderOpen()
    Add-PetDrawing `
        -Context $context `
        -Phase $script:phase `
        -Reaction $script:reaction `
        -Facing $script:facing `
        -Moving $script:moving `
        -Tired $script:tiredExpression
    $context.Close()
}

function Invoke-PetHop {
    param([double]$Strength = 1.0)

    $script:reaction = [Math]::Min(1.25, $script:reaction + $Strength)
}

function Invoke-PetSpeech {
    param([string]$Text = '宝宝，我爱你')

    if ($null -eq $script:speech) {
        return
    }

    try {
        $script:speech.SpeakAsyncCancelAll()
        [void]$script:speech.SpeakAsync($Text)
    }
    catch {
        # Speech should never stop the interaction if the system voice is busy.
    }
}

$timer = [System.Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromMilliseconds(32)
$timer.Add_Tick({
    Render-Pet
})

$hopItem = [System.Windows.Controls.MenuItem]::new()
$hopItem.Header = '跳一下'
$hopItem.Add_Click({ Invoke-PetHop -Strength 1.0 })

$nudgeItem = [System.Windows.Controls.MenuItem]::new()
$nudgeItem.Header = '开心一下'
$nudgeItem.Add_Click({ Invoke-PetHop -Strength 0.7 })

$crawlItem = [System.Windows.Controls.MenuItem]::new()
$crawlItem.Header = '自动爬行'
$crawlItem.IsCheckable = $true
$crawlItem.IsChecked = $true
$crawlItem.Add_Click({
    $script:autoCrawl = $crawlItem.IsChecked
})

$startupKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$startupValueName = 'CodexDesktopPet'
$launcherPath = Join-Path $root '桌面宠物.exe'
$startupCommand = if (Test-Path -LiteralPath $launcherPath) {
    '"' + $launcherPath + '" --startup'
}
else {
    'wscript.exe "' + (Join-Path $root 'start-pet.vbs') + '"'
}
$startupEnabled = $false
try {
    $startupProperty = Get-ItemProperty -Path $startupKey -Name $startupValueName -ErrorAction Stop
    $startupEnabled = -not [string]::IsNullOrWhiteSpace(
        $startupProperty.PSObject.Properties[$startupValueName].Value
    )
}
catch {
    $startupEnabled = $false
}

$startupItem = [System.Windows.Controls.MenuItem]::new()
$startupItem.Header = '开机自动启动'
$startupItem.IsCheckable = $true
$startupItem.IsChecked = $startupEnabled
$startupItem.Add_Click({
    try {
        if ($startupItem.IsChecked) {
            New-ItemProperty `
                -Path $startupKey `
                -Name $startupValueName `
                -Value $startupCommand `
                -PropertyType String `
                -Force | Out-Null
        }
        else {
            Remove-ItemProperty `
                -Path $startupKey `
                -Name $startupValueName `
                -ErrorAction SilentlyContinue
        }
    }
    catch {
        $startupItem.IsChecked = -not $startupItem.IsChecked
    }
})

$topmostItem = [System.Windows.Controls.MenuItem]::new()
$topmostItem.Header = '始终置顶'
$topmostItem.IsCheckable = $true
$topmostItem.IsChecked = $true
$topmostItem.Add_Click({
    $window.Topmost = $topmostItem.IsChecked
})

$exitItem = [System.Windows.Controls.MenuItem]::new()
$exitItem.Header = '退出'
$exitItem.Add_Click({ $window.Close() })

$menu = [System.Windows.Controls.ContextMenu]::new()
$menu.Items.Add($hopItem) | Out-Null
$menu.Items.Add($nudgeItem) | Out-Null
$menu.Items.Add([System.Windows.Controls.Separator]::new()) | Out-Null
$menu.Items.Add($crawlItem) | Out-Null
$menu.Items.Add($startupItem) | Out-Null
$menu.Items.Add($topmostItem) | Out-Null
$menu.Items.Add($exitItem) | Out-Null
$window.ContextMenu = $menu

$window.Add_MouseLeftButtonDown({
    param($sender, $eventArgs)

    $script:dragging = $true
    $script:dragMoved = $false
    $script:dragStartScreen = $sender.PointToScreen($eventArgs.GetPosition($sender))
    $script:dragStartWindow = [System.Windows.Point]::new($sender.Left, $sender.Top)
    $sender.CaptureMouse() | Out-Null
    $eventArgs.Handled = $true
})

$window.Add_MouseMove({
    param($sender, $eventArgs)

    if (-not $script:dragging) {
        return
    }

    $screenPoint = $sender.PointToScreen($eventArgs.GetPosition($sender))
    $deltaX = $screenPoint.X - $script:dragStartScreen.X
    $deltaY = $screenPoint.Y - $script:dragStartScreen.Y

    if ([Math]::Abs($deltaX) + [Math]::Abs($deltaY) -gt 3) {
        $script:dragMoved = $true
    }

    $sender.Left = $script:dragStartWindow.X + $deltaX
    $sender.Top = $script:dragStartWindow.Y + $deltaY
})

$window.Add_MouseLeftButtonUp({
    param($sender, $eventArgs)

    $sender.ReleaseMouseCapture()
    $script:dragging = $false
    if (-not $script:dragMoved) {
        Invoke-PetHop -Strength 0.85
        Invoke-PetSpeech
    }
    $eventArgs.Handled = $true
})

$window.Add_Closed({
    $timer.Stop()
    if ($null -ne $script:speech) {
        $script:speech.Dispose()
    }
})

$window.Add_Loaded({
    Render-Pet
    $timer.Start()
})

[void]$window.ShowDialog()
