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

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($PreviewPath)) {
    $PreviewPath = Join-Path $root 'assets\face-manager-preview.png'
}
. (Join-Path $root 'scripts\face-library.ps1')

function New-FaceThumbnail {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $image = [System.Windows.Media.Imaging.BitmapImage]::new()
    $image.BeginInit()
    $image.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $image.DecodePixelWidth = 120
    $image.UriSource = [System.Uri]::new($Path)
    $image.EndInit()
    $image.Freeze()
    return $image
}

$xamlPath = Join-Path $root 'ui\face-manager.xaml'
$xml = [System.Xml.XmlDocument]::new()
$xml.Load($xamlPath)
$reader = [System.Xml.XmlNodeReader]::new($xml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$faceList = $window.FindName('FaceList')
$facePreview = $window.FindName('FacePreview')
$emptyState = $window.FindName('EmptyState')
$uploadButton = $window.FindName('UploadButton')
$applyButton = $window.FindName('ApplyButton')
$deleteButton = $window.FindName('DeleteButton')
$statusText = $window.FindName('StatusText')

$script:library = Initialize-FaceLibrary -Root $root
$script:selectedFace = $null

function Refresh-FaceManager {
    param([string]$SelectId)

    $script:library = Read-FaceLibrary -Root $root
    $paths = Get-FaceLibraryPaths -Root $root
    $rows = @(
        foreach ($face in $script:library.faces) {
            $facePath = Join-Path $paths.Directory $face.file
            [pscustomobject]@{
                Face = $face
                DisplayName = $face.name
                StateText = if ($face.id -eq $script:library.currentId) { '当前使用' } elseif ($face.isDefault) { '默认' } else { '已保存' }
                Thumbnail = New-FaceThumbnail -Path $facePath
            }
        }
    )

    $faceList.ItemsSource = $rows
    if ($rows.Count -eq 0) {
        $script:selectedFace = $null
        return
    }

    $target = $rows |
        Where-Object { $_.Face.id -eq $SelectId } |
        Select-Object -First 1
    if ($null -eq $target) {
        $target = $rows |
            Where-Object { $_.Face.id -eq $script:library.currentId } |
            Select-Object -First 1
    }
    if ($null -eq $target) {
        $target = $rows[0]
    }
    $faceList.SelectedItem = $target
}

function Update-FaceSelection {
    $selected = $faceList.SelectedItem
    if ($null -eq $selected) {
        $script:selectedFace = $null
        $facePreview.Source = $null
        $emptyState.Visibility = [System.Windows.Visibility]::Visible
        $applyButton.IsEnabled = $false
        $deleteButton.IsEnabled = $false
        return
    }

    $script:selectedFace = $selected.Face
    $paths = Get-FaceLibraryPaths -Root $root
    $facePath = Join-Path $paths.Directory $script:selectedFace.file
    $facePreview.Source = New-FaceThumbnail -Path $facePath
    $emptyState.Visibility = [System.Windows.Visibility]::Collapsed
    $applyButton.IsEnabled = $script:selectedFace.id -ne $script:library.currentId
    $deleteButton.IsEnabled = -not $script:selectedFace.isDefault
}

$faceList.Add_SelectionChanged({
    Update-FaceSelection
})

$uploadButton.Add_Click({
    $dialog = [System.Windows.Forms.OpenFileDialog]::new()
    $dialog.Title = '选择人脸照片'
    $dialog.Filter = '图片文件|*.jpg;*.jpeg;*.png;*.bmp;*.webp|所有文件|*.*'
    $dialog.Multiselect = $false

    try {
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }

        $statusText.Text = '正在识别并处理人脸...'
        $window.Dispatcher.Invoke(
            [System.Windows.Threading.DispatcherPriority]::Render,
            [Action] {}
        )

        $newFace = Import-FacePhoto `
            -ImagePath $dialog.FileName `
            -Root $root
        Refresh-FaceManager -SelectId $newFace.id
        $statusText.Text = '人脸已上传并应用。'
    }
    catch {
        $statusText.Text = $_.Exception.Message
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            '无法上传人脸',
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        ) | Out-Null
    }
})

$applyButton.Add_Click({
    if ($null -eq $script:selectedFace) {
        return
    }

    try {
        Set-CurrentFace -FaceId $script:selectedFace.id -Root $root
        Refresh-FaceManager -SelectId $script:selectedFace.id
        $statusText.Text = '已设置为当前人脸。'
    }
    catch {
        $statusText.Text = $_.Exception.Message
    }
})

$deleteButton.Add_Click({
    if ($null -eq $script:selectedFace -or $script:selectedFace.isDefault) {
        return
    }

    $answer = [System.Windows.MessageBox]::Show(
        "确定删除 [$($script:selectedFace.name)] 吗？",
        '删除人脸',
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }

    try {
        Remove-Face -FaceId $script:selectedFace.id -Root $root
        Refresh-FaceManager
        $statusText.Text = '人脸已删除。'
    }
    catch {
        $statusText.Text = $_.Exception.Message
    }
})

$window.Add_Loaded({
    Refresh-FaceManager
})

if ($ExportPreview) {
    Refresh-FaceManager
    $window.Show()
    $window.UpdateLayout()
    $previewBitmap = [System.Windows.Media.Imaging.RenderTargetBitmap]::new(
        [int]$window.ActualWidth,
        [int]$window.ActualHeight,
        96,
        96,
        [System.Windows.Media.PixelFormats]::Pbgra32
    )
    $previewBitmap.Render($window)
    $previewDirectory = Split-Path -Parent $PreviewPath
    New-Item -ItemType Directory -Force -Path $previewDirectory | Out-Null
    $previewStream = [System.IO.File]::Create($PreviewPath)
    try {
        $previewEncoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
        $previewEncoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($previewBitmap))
        $previewEncoder.Save($previewStream)
    }
    finally {
        $previewStream.Dispose()
        $window.Close()
    }
    Write-Output $PreviewPath
    return
}

[void]$window.ShowDialog()
