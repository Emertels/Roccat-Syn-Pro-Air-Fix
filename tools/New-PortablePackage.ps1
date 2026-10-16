param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptSource = Join-Path $repoRoot 'Roccat-SynPro-Manager.ps1'
$launcherSource = Join-Path $repoRoot 'Roccat-SynPro-Manager.vbs'
$translationSource = Join-Path $repoRoot 'i18n.json'
$marker = '@@ROCCAT_I18N_JSON_EMBED@@'
$archiveName = 'Roccat-Syn-Pro-Air-Fix-v1.2.0-Portable.zip'

foreach ($requiredFile in @($scriptSource, $launcherSource, $translationSource)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required package source is missing: $requiredFile"
    }
}

$sourceText = [System.IO.File]::ReadAllText($scriptSource, [System.Text.Encoding]::UTF8)
$translationJson = [System.IO.File]::ReadAllText($translationSource, [System.Text.Encoding]::UTF8).Trim()
$markerCount = [System.Text.RegularExpressions.Regex]::Matches($sourceText, [System.Text.RegularExpressions.Regex]::Escape($marker)).Count
if ($markerCount -ne 1) { throw "Expected exactly one translation marker; found $markerCount." }
$portableScript = $sourceText.Replace($marker, $translationJson)
if ($portableScript.Contains($marker)) { throw 'The translation marker was not fully replaced.' }

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputPath = Join-Path ([System.IO.Path]::GetFullPath($OutputDirectory)) $archiveName
$stageDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ('RoccatSynProPackage-' + [guid]::NewGuid().ToString('N'))
$stageFullPath = [System.IO.Path]::GetFullPath($stageDirectory)
$tempFullPath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
if (-not $stageFullPath.StartsWith($tempFullPath, [System.StringComparison]::OrdinalIgnoreCase) -or
    -not (Split-Path -Leaf $stageFullPath).StartsWith('RoccatSynProPackage-', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to use an unexpected temporary directory.'
}

try {
    New-Item -ItemType Directory -Path $stageFullPath -ErrorAction Stop | Out-Null
    $scriptStagePath = Join-Path $stageFullPath 'Roccat-SynPro-Manager.ps1'
    $launcherStagePath = Join-Path $stageFullPath 'Roccat-SynPro-Manager.vbs'
    [System.IO.File]::WriteAllText($scriptStagePath, $portableScript, (New-Object System.Text.UTF8Encoding($true)))
    Copy-Item -LiteralPath $launcherSource -Destination $launcherStagePath -Force

    if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath -Force }
    Compress-Archive -LiteralPath @($scriptStagePath, $launcherStagePath) -DestinationPath $outputPath -CompressionLevel Optimal -Force

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($outputPath)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName })
        $expected = @('Roccat-SynPro-Manager.ps1', 'Roccat-SynPro-Manager.vbs')
        if ($entries.Count -ne 2 -or @($entries | Where-Object { $_ -notin $expected }).Count -gt 0 -or
            @($expected | Where-Object { $_ -notin $entries }).Count -gt 0) {
            throw "Unexpected ZIP contents: $($entries -join ', ')"
        }
    } finally { $archive.Dispose() }

    Write-Output "Created and inspected: $outputPath"
    Write-Output 'ZIP contents: Roccat-SynPro-Manager.ps1, Roccat-SynPro-Manager.vbs'
} finally {
    if ((Test-Path -LiteralPath $stageFullPath) -and
        $stageFullPath.StartsWith($tempFullPath, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $stageFullPath).StartsWith('RoccatSynProPackage-', [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $stageFullPath -Recurse -Force
    }
}
