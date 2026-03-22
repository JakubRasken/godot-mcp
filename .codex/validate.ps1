param(
    [string]$ProjectPath = ".",
    [string]$Godot = "",
    [string]$Dotnet = "",
    [switch]$SkipImport,
    [switch]$SkipCheckOnly,
    [switch]$SkipDotnetBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Windows validation companion for the forked local bootstrap path.

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Resolve-ExistingPath {
    param([string]$PathValue)

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $null
    }

    if (Test-Path $PathValue) {
        return (Resolve-Path $PathValue).Path
    }

    return $null
}

function Resolve-GodotCommand {
    param([string]$RequestedPath)

    $requested = Resolve-ExistingPath -PathValue $RequestedPath
    if ($requested) {
        return $requested
    }

    $fromEnv = Resolve-ExistingPath -PathValue $env:GODOT
    if ($fromEnv) {
        return $fromEnv
    }

    $localRoot = Join-Path $RepoRoot ".local\godot-mono"
    if (Test-Path $localRoot) {
        $local = Get-ChildItem -Path $localRoot -Filter "*.exe" -Recurse -File |
            Where-Object { $_.Name -like "Godot_v*_mono_win*.exe" } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($local) {
            return $local.FullName
        }
    }

    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return $null
}

function Resolve-DotnetCommand {
    param([string]$RequestedPath)

    $requested = Resolve-ExistingPath -PathValue $RequestedPath
    if ($requested) {
        return $requested
    }

    $localDotnet = Join-Path $RepoRoot ".local\dotnet\dotnet.exe"
    if (Test-Path $localDotnet) {
        return $localDotnet
    }

    $command = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return $null
}

function Invoke-Checked {
    param(
        [string]$Label,
        [string]$Executable,
        [string[]]$Arguments
    )

    Write-Host ""
    Write-Host ("==> {0}" -f $Label)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("{0} failed with exit code {1}." -f $Label, $LASTEXITCODE)
    }
}

$ResolvedProjectPath = (Resolve-Path $ProjectPath).Path
$ProjectFile = Join-Path $ResolvedProjectPath "project.godot"
$GodotExe = Resolve-GodotCommand -RequestedPath $Godot
$DotnetExe = Resolve-DotnetCommand -RequestedPath $Dotnet

if ($DotnetExe) {
    $DotnetRoot = Split-Path $DotnetExe -Parent
    $env:DOTNET_ROOT = $DotnetRoot
    $env:PATH = "$DotnetRoot;$env:PATH"
}

if ((-not $SkipImport -or -not $SkipCheckOnly) -and -not (Test-Path $ProjectFile)) {
    Write-Warning "No project.godot was found under $ResolvedProjectPath. Skipping Godot validation."
    $SkipImport = $true
    $SkipCheckOnly = $true
}

if ((-not $SkipImport -or -not $SkipCheckOnly) -and -not $GodotExe) {
    throw "Godot was requested but no executable was found. Run .codex/setup.ps1 first or set `$env:GODOT."
}

if (-not $SkipImport) {
    Invoke-Checked `
        -Label "Godot import pass" `
        -Executable $GodotExe `
        -Arguments @("--headless", "--editor", "--import", "--quit", "--path", $ResolvedProjectPath)
}

if (-not $SkipCheckOnly) {
    Invoke-Checked `
        -Label "Godot script parse" `
        -Executable $GodotExe `
        -Arguments @("--headless", "--editor", "--check-only", "--quit", "--path", $ResolvedProjectPath)
}

if (-not $SkipDotnetBuild) {
    $Solutions = @(Get-ChildItem -Path $ResolvedProjectPath -Filter "*.sln" -Recurse -File |
        Where-Object {
            $_.FullName -notmatch "\\(\.git|\.godot|\.local)\\"
        })

    if ($Solutions.Count -eq 0) {
        Write-Host ""
        Write-Host "==> dotnet build"
        Write-Host "No .sln files found. Skipping C# build."
    } else {
        if (-not $DotnetExe) {
            throw ".NET build was requested but no dotnet executable was found. Run .codex/setup.ps1 first."
        }

        foreach ($Solution in $Solutions) {
            $LogPath = Join-Path ([System.IO.Path]::GetTempPath()) ("dotnet_build_{0}.log" -f ([System.IO.Path]::GetFileNameWithoutExtension($Solution.Name)))
            Write-Host ""
            Write-Host ("==> dotnet build {0}" -f $Solution.FullName)
            & $DotnetExe build $Solution.FullName *> $LogPath
            if ($LASTEXITCODE -ne 0) {
                Get-Content -Path $LogPath -Tail 40
                throw ("dotnet build failed for {0}. Full log: {1}" -f $Solution.FullName, $LogPath)
            }

            Get-Content -Path $LogPath -Tail 20
        }
    }
}

Write-Host ""
Write-Host "Validation completed."
