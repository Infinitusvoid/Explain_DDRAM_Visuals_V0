# Shared environment for the DRAM series tooling.
# Dot-source this from the other scripts:  . "$PSScriptRoot\env.ps1"

$ErrorActionPreference = 'Stop'

$global:REPO_ROOT   = Split-Path -Parent $PSScriptRoot
$global:ENGINE_ZIP  = Join-Path $global:REPO_ROOT 'TheNewStatelessPointcloudEngine_V1_Runtime.zip'
$global:ENGINE_DIR  = Join-Path $global:REPO_ROOT 'TheNewStatelessPointcloudEngine_V1_Runtime'
$global:ENGINE_EXE  = Join-Path $global:ENGINE_DIR 'engine.exe'
$global:SERIES_DIR  = Join-Path $global:REPO_ROOT 'series'
$global:CONTENT_DIR = Join-Path $global:SERIES_DIR '_content'
$global:KIT_DIR     = Join-Path $global:SERIES_DIR '_kit'
$global:DELIV_DIR   = Join-Path $global:REPO_ROOT 'deliverables'
$global:WORK_DIR    = Join-Path $global:REPO_ROOT 'work'
$global:AUDIO_DIR   = Join-Path $global:WORK_DIR 'audio'

# The six films. Keep in sync with tools\assemble.ps1 and series\_content\*.as
$global:EPISODE_DEFS = @(
    [pscustomobject]@{ Id = 'ep01'; Slug = 'The_Leaky_Bucket';     Title = 'The Leaky Bucket';     Seconds = 46 },
    [pscustomobject]@{ Id = 'ep02'; Slug = 'The_Refresh_Cycle';    Title = 'The Refresh Cycle';    Seconds = 44 },
    [pscustomobject]@{ Id = 'ep03'; Slug = 'Rows_Columns_Banks';   Title = 'Rows, Columns, Banks'; Seconds = 40 },
    [pscustomobject]@{ Id = 'ep04'; Slug = 'The_Read_Transaction'; Title = 'The Read Transaction'; Seconds = 44 },
    [pscustomobject]@{ Id = 'ep05'; Slug = 'Double_Data_Rate';     Title = 'Double Data Rate';     Seconds = 42 },
    [pscustomobject]@{ Id = 'ep06'; Slug = 'Inside_a_DIMM';        Title = 'Inside a DIMM';        Seconds = 44 }
)

function Find-Python {
    $candidates = @()
    if (Get-Command python -ErrorAction SilentlyContinue) { $candidates += [pscustomobject]@{ Exe = 'python'; Pre = @() } }
    if (Get-Command py     -ErrorAction SilentlyContinue) { $candidates += [pscustomobject]@{ Exe = 'py';     Pre = @('-3') } }
    $bundled = 'C:\Users\Cosmos\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe'
    if (Test-Path $bundled) { $candidates += [pscustomobject]@{ Exe = $bundled; Pre = @() } }

    foreach ($c in $candidates) {
        try {
            $null = & $c.Exe @($c.Pre + @('-c', 'import PIL, sys; sys.exit(0)')) 2>$null
            if ($LASTEXITCODE -eq 0) { return $c }
        } catch { }
    }
    throw "Python with Pillow was not found. Install Python 3 and run: pip install pillow"
}

if (-not $global:PY) { $global:PY = Find-Python }

function Invoke-Py {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & $global:PY.Exe @($global:PY.Pre + $Arguments)
    if ($LASTEXITCODE -ne 0) { throw "python failed: $($Arguments -join ' ')" }
}

function Ensure-Engine {
    if (Test-Path $global:ENGINE_EXE) { return }
    if (-not (Test-Path $global:ENGINE_ZIP)) {
        throw "Engine not found. Expected '$($global:ENGINE_DIR)' or '$($global:ENGINE_ZIP)'."
    }
    Write-Host "  engine runtime missing - extracting $([System.IO.Path]::GetFileName($global:ENGINE_ZIP)) ..." -ForegroundColor DarkGray
    Expand-Archive -Path $global:ENGINE_ZIP -DestinationPath $global:REPO_ROOT -Force
    if (-not (Test-Path $global:ENGINE_EXE)) { throw "Extraction finished but engine.exe is still missing." }
}

function Ensure-Tooling {
    Ensure-Engine
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        throw "FFmpeg was not found on PATH. Install it (winget install Gyan.FFmpeg) and reopen the terminal."
    }
    foreach ($f in @('make_cards.py', 'make_audio.py', 'make_intro.py')) {
        if (-not (Test-Path (Join-Path $PSScriptRoot $f))) { throw "missing tool script: $f" }
    }
    New-Item -ItemType Directory -Force -Path $global:DELIV_DIR, $global:AUDIO_DIR, (Join-Path $global:DELIV_DIR 'posters'), (Join-Path $global:DELIV_DIR 'thumbnails') | Out-Null
}

function Get-Episode([string]$id) {
    $e = $global:EPISODE_DEFS | Where-Object { $_.Id -eq $id }
    if (-not $e) { throw "unknown episode '$id' (expected ep01..ep06)" }
    return $e
}

function Format-Duration([double]$seconds) {
    $m = [math]::Floor($seconds / 60)
    $s = [math]::Round($seconds - $m * 60)
    return ("{0}:{1:00}" -f [int]$m, [int]$s)
}

