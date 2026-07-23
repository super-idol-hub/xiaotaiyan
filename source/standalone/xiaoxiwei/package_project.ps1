param(
    [string]$ProjectDirectory = '小泰妍'
)

$ErrorActionPreference = 'Stop'

$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$project = [IO.Path]::GetFullPath((Join-Path $workspace $ProjectDirectory))
$workspacePrefix = $workspace.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $project.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Project directory escaped the workspace.'
}
$projectPrefix = $project.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar

function Ensure-Directory([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Reset-ProjectDirectory([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($projectPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to reset a directory outside the project: $fullPath"
    }
    if (Test-Path -LiteralPath $fullPath) {
        Remove-Item -LiteralPath $fullPath -Recurse -Force
    }
    Ensure-Directory $fullPath
}

function Copy-DirectoryContents([string]$Source, [string]$Destination) {
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        throw "Missing source directory: $Source"
    }
    Ensure-Directory $Destination
    Get-ChildItem -Force -LiteralPath $Source | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
}

$release = Join-Path $project 'releases\最新版'
$releaseSkins = Join-Path $release 'skins'
$source = Join-Path $project 'source'
$qa = Join-Path $project 'qa'
$history = Join-Path $project 'releases\历史版本'
Ensure-Directory $history
$previousV3 = Join-Path $release '小泰妍-Windows互动角色-v3.0-增强版.exe'
if (Test-Path -LiteralPath $previousV3 -PathType Leaf) {
    Copy-Item -LiteralPath $previousV3 -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0-增强版.exe') -Force
}
$previousV301 = Join-Path $release '小泰妍-Windows互动角色-v3.0.1-增强版.exe'
if (Test-Path -LiteralPath $previousV301 -PathType Leaf) {
    Copy-Item -LiteralPath $previousV301 -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0.1-增强版.exe') -Force
}
$previousV302 = Join-Path $release '小泰妍-Windows互动角色-v3.0.2-增强版.exe'
if (Test-Path -LiteralPath $previousV302 -PathType Leaf) {
    Copy-Item -LiteralPath $previousV302 -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0.2-增强版.exe') -Force
}
$previousV303 = Join-Path $release '小泰妍-Windows互动角色-v3.0.3-增强版.exe'
if (Test-Path -LiteralPath $previousV303 -PathType Leaf) {
    Copy-Item -LiteralPath $previousV303 -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0.3-增强版.exe') -Force
}
$previousV304Legacy = Join-Path $release '小泰妍-Windows互动角色-v3.0.4-增强版.exe'
if (Test-Path -LiteralPath $previousV304Legacy -PathType Leaf) {
    Copy-Item -LiteralPath $previousV304Legacy -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0.4-增强版.exe') -Force
}
$currentLatest = Join-Path $release '小泰妍.exe'
if (Test-Path -LiteralPath $currentLatest -PathType Leaf) {
    $currentLatestVersion = (Get-Item -LiteralPath $currentLatest).VersionInfo.FileVersion
    if ($currentLatestVersion -and $currentLatestVersion.StartsWith('3.0.5', [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $currentLatest -Destination (Join-Path $history '小泰妍-Windows互动角色-v3.0.5-增强版.exe') -Force
    }
}
Reset-ProjectDirectory $release
Reset-ProjectDirectory $source
Reset-ProjectDirectory $qa
Ensure-Directory $releaseSkins

$builtExe = Join-Path $workspace 'outputs\taeyeon-standalone-4k-v1\小泰妍.exe'
$releaseExe = Join-Path $release '小泰妍.exe'
Copy-Item -LiteralPath $builtExe -Destination $releaseExe -Force

foreach ($skinId in @('taeyeon-invu')) {
    $skinSource = Join-Path $workspace ("outputs\taeyeon-skins\{0}" -f $skinId)
    $skinTarget = Join-Path $releaseSkins $skinId
    Ensure-Directory $skinTarget
    Copy-Item -LiteralPath (Join-Path $skinSource 'skin.xml') -Destination $skinTarget -Force
    Copy-Item -LiteralPath (Join-Path $skinSource 'frames.zip') -Destination $skinTarget -Force

    $skinQaTarget = Join-Path $qa ("skins\{0}" -f $skinId)
    Copy-DirectoryContents (Join-Path $skinSource 'qa') $skinQaTarget
}

Copy-Item -LiteralPath (Join-Path $project 'README.md') -Destination (Join-Path $release 'README.md') -Force
Copy-Item -LiteralPath (Join-Path $project 'docs\使用说明.md') -Destination (Join-Path $release '使用说明.md') -Force
Copy-Item -LiteralPath (Join-Path $project 'docs\皮肤包接口.md') -Destination (Join-Path $release '皮肤包接口.md') -Force

Copy-DirectoryContents (Join-Path $workspace 'standalone\xiaoxiwei') (Join-Path $source 'standalone\xiaoxiwei')
Copy-DirectoryContents (Join-Path $workspace 'work\taeyeon') (Join-Path $source 'work\taeyeon')
Copy-DirectoryContents (Join-Path $workspace 'outputs\taeyeon-standalone-4k-v1') (Join-Path $qa 'built-in-and-runtime')

$materialNames = @()
$materialSource = Join-Path $env:LOCALAPPDATA 'Temp'
$materialTarget = Join-Path $source 'user-materials'
Ensure-Directory $materialTarget
$missingMaterials = @()
foreach ($name in $materialNames) {
    $path = Join-Path $materialSource $name
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Copy-Item -LiteralPath $path -Destination $materialTarget -Force
    } else {
        $missingMaterials += $name
    }
}

$hashPath = Join-Path $release 'SHA256SUMS.txt'
$releaseFiles = Get-ChildItem -LiteralPath $release -Recurse -File |
    Where-Object { -not $_.FullName.Equals($hashPath, [StringComparison]::OrdinalIgnoreCase) } |
    Sort-Object FullName
$hashLines = foreach ($file in $releaseFiles) {
    $relative = $file.FullName.Substring($release.Length).TrimStart('\')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
    "{0}  {1}" -f $hash, $relative
}
[IO.File]::WriteAllLines($hashPath, $hashLines, [Text.UTF8Encoding]::new($false))

$releaseArchive = Join-Path (Split-Path -Parent $release) '小泰妍-完整包.zip'
$releaseArchive = [IO.Path]::GetFullPath($releaseArchive)
if (-not $releaseArchive.StartsWith($projectPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Release archive escaped the project: $releaseArchive"
}
if (Test-Path -LiteralPath $releaseArchive) {
    Remove-Item -LiteralPath $releaseArchive -Force
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory(
    $release,
    $releaseArchive,
    [IO.Compression.CompressionLevel]::Optimal,
    $false
)

$historicalRelativePaths = @()
$historicalExecutables = foreach ($relativePath in $historicalRelativePaths) {
    $historicalPath = Join-Path $project $relativePath
    if (-not (Test-Path -LiteralPath $historicalPath -PathType Leaf)) {
        throw "Missing historical executable: $historicalPath"
    }
    [ordered]@{
        path = $relativePath
        bytes = (Get-Item -LiteralPath $historicalPath).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $historicalPath).Hash.ToLowerInvariant()
    }
}

$summary = [ordered]@{
    schemaVersion = 1
    packagedAt = [DateTimeOffset]::Now.ToString('o')
    developer = 'Anbunensi'
    executable = [ordered]@{
        path = 'releases\最新版\小泰妍.exe'
        bytes = (Get-Item -LiteralPath $releaseExe).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $releaseExe).Hash.ToLowerInvariant()
    }
    releaseArchive = [ordered]@{
        path = 'releases\小泰妍-完整包.zip'
        bytes = (Get-Item -LiteralPath $releaseArchive).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $releaseArchive).Hash.ToLowerInvariant()
    }
    skins = @('taeyeon-invu')
    historicalExecutables = @($historicalExecutables)
    copiedUserMaterials = $materialNames.Count - $missingMaterials.Count
    missingUserMaterials = $missingMaterials
}
$summaryPath = Join-Path $project 'PROJECT-MANIFEST.json'
[IO.File]::WriteAllText(
    $summaryPath,
    (($summary | ConvertTo-Json -Depth 6) + "`n"),
    [Text.UTF8Encoding]::new($false)
)

[pscustomobject]@{
    Project = $project
    ReleaseExecutable = $releaseExe
    ReleaseArchive = $releaseArchive
    ReleaseFiles = $releaseFiles.Count + 1
    CopiedUserMaterials = $materialNames.Count - $missingMaterials.Count
    MissingUserMaterials = $missingMaterials.Count
}
