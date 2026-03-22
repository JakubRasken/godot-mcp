param(
    [string]$GodotTag = "4.6-stable",
    [string]$GodotRepo = "godotengine/godot",
    [string]$DotnetChannel = "9.0",
    [switch]$SkipGodot,
    [switch]$SkipDotnet,
    [switch]$SkipPythonTools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$LocalRoot = Join-Path $RepoRoot ".local"
$DownloadRoot = Join-Path $LocalRoot "downloads"
$DotnetRoot = Join-Path $LocalRoot "dotnet"
$VenvRoot = Join-Path $LocalRoot "venv"
$GodotRoot = Join-Path $LocalRoot "godot-mono"

function Write-Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message"
}

function Invoke-WithRetry {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [int]$Attempts = 3,
        [int]$DelaySeconds = 2,
        [string]$Label = "operation"
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            & $ScriptBlock
            return
        } catch {
            if ($attempt -ge $Attempts) {
                throw
            }

            Write-Warning ("{0} failed ({1}/{2}): {3}" -f $Label, $attempt, $Attempts, $_.Exception.Message)
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$Destination,
        [string]$Label
    )

    Ensure-Directory -Path (Split-Path -Parent $Destination)
    Invoke-WithRetry -Label $Label -ScriptBlock {
        Invoke-WebRequest -Uri $Url -OutFile $Destination
    }
}

function Get-GodotArchiveName {
    param([string]$Tag)

    return "Godot_v{0}_mono_win64.zip" -f $Tag
}

function Get-GodotExecutablePath {
    param([string]$Tag)

    $installRoot = Join-Path $GodotRoot $Tag
    if (-not (Test-Path $installRoot)) {
        return Join-Path $installRoot ("Godot_v{0}_mono_win64_console.exe" -f $Tag)
    }

    $consoleExe = Get-ChildItem -Path $installRoot -Filter "*_console.exe" -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if ($consoleExe) {
        return $consoleExe.FullName
    }

    $editorExe = Get-ChildItem -Path $installRoot -Filter "*.exe" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "*_console.exe" } |
        Sort-Object FullName |
        Select-Object -First 1
    if ($editorExe) {
        return $editorExe.FullName
    }

    return Join-Path $installRoot ("Godot_v{0}_mono_win64_console.exe" -f $Tag)
}

Ensure-Directory -Path $LocalRoot
Ensure-Directory -Path $DownloadRoot

Write-Section "Repo root"
Write-Host $RepoRoot

if (-not $SkipPythonTools) {
    Write-Section "Python tools"

    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw "python was not found in PATH."
    }

    if (-not (Test-Path $VenvRoot)) {
        & python -m venv $VenvRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create virtual environment at $VenvRoot."
        }
    }

    $VenvPython = Join-Path $VenvRoot "Scripts\python.exe"
    $PreCommit = Join-Path $VenvRoot "Scripts\pre-commit.exe"

    & $VenvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upgrade pip inside $VenvRoot."
    }

    & $VenvPython -m pip install "gdtoolkit==4.*" "pre-commit>=4.2,<5"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install gdtoolkit/pre-commit into $VenvRoot."
    }

    if ((Test-Path (Join-Path $RepoRoot ".git")) -and (Test-Path $PreCommit)) {
        & $PreCommit install --install-hooks
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "pre-commit hook install failed; continuing."
        }
    }
}

if (-not $SkipDotnet) {
    Write-Section ".NET SDK"

    Ensure-Directory -Path $DotnetRoot
    $DotnetExe = Join-Path $DotnetRoot "dotnet.exe"
    $DotnetInstallScript = Join-Path $DownloadRoot "dotnet-install.ps1"
    $InstalledSdkMatchesChannel = $false

    if (Test-Path $DotnetExe) {
        $InstalledSdks = & $DotnetExe --list-sdks
        if ($LASTEXITCODE -eq 0) {
            $InstalledSdkMatchesChannel = @($InstalledSdks | Where-Object { $_ -like "$DotnetChannel*" }).Count -gt 0
        }
    }

    if ((-not (Test-Path $DotnetExe)) -or (-not $InstalledSdkMatchesChannel)) {
        Download-File `
            -Url "https://dot.net/v1/dotnet-install.ps1" `
            -Destination $DotnetInstallScript `
            -Label "dotnet-install download"

        & powershell -NoProfile -ExecutionPolicy Bypass -File $DotnetInstallScript -Channel $DotnetChannel -InstallDir $DotnetRoot -NoPath
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $DotnetExe)) {
            throw "Failed to install .NET SDK into $DotnetRoot."
        }
    }

    & $DotnetExe --info | Select-Object -First 20
}

if (-not $SkipGodot) {
    Write-Section "Godot mono"

    $GodotArchive = Get-GodotArchiveName -Tag $GodotTag
    $GodotZipPath = Join-Path $DownloadRoot $GodotArchive
    $GodotInstallDir = Join-Path $GodotRoot $GodotTag

    if (-not (Test-Path (Get-GodotExecutablePath -Tag $GodotTag))) {
        Ensure-Directory -Path $GodotInstallDir
        Download-File `
            -Url ("https://github.com/{0}/releases/download/{1}/{2}" -f $GodotRepo, $GodotTag, $GodotArchive) `
            -Destination $GodotZipPath `
            -Label "Godot mono download"

        Expand-Archive -Path $GodotZipPath -DestinationPath $GodotInstallDir -Force
        if (-not (Test-Path (Get-GodotExecutablePath -Tag $GodotTag))) {
            throw "Godot executable was not found after extracting $GodotArchive."
        }
    }

    $GodotExe = Get-GodotExecutablePath -Tag $GodotTag
    $SelfContainedMarker = Join-Path (Split-Path $GodotExe -Parent) "_sc_"
    if (-not (Test-Path $SelfContainedMarker)) {
        New-Item -ItemType File -Path $SelfContainedMarker | Out-Null
    }
    & $GodotExe --version
    if ($LASTEXITCODE -ne 0) {
        throw "Godot executable exists but could not be started: $GodotExe"
    }
}

Write-Section "Finished"
Write-Host ("Local tools root : {0}" -f $LocalRoot)
if (-not $SkipPythonTools) {
    Write-Host ("gdformat path    : {0}" -f (Join-Path $VenvRoot "Scripts\gdformat.exe"))
    Write-Host ("gdlint path      : {0}" -f (Join-Path $VenvRoot "Scripts\gdlint.exe"))
}
if (-not $SkipDotnet) {
    Write-Host ("dotnet path      : {0}" -f (Join-Path $DotnetRoot "dotnet.exe"))
}
if (-not $SkipGodot) {
    Write-Host ("godot path       : {0}" -f (Get-GodotExecutablePath -Tag $GodotTag))
}
Write-Host "Use `$env:GODOT and `$env:DOTNET_ROOT if you want to pin these paths in the current shell."
