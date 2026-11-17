param(
    [string[]]$Episodes = @(),
    [switch]$Quick,
    [switch]$SkipAssemble
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

function Write-Step([string]$text) {
    Write-Host ""
    Write-Host ("==> " + $text) -ForegroundColor Cyan
}

function Write-Info([string]$text) {
    Write-Host ("    " + $text) -ForegroundColor DarkGray
}

$started = Get-Date
Write-Host ""
Write-Host "  HOW DRAM WORKS - one-click video generator" -ForegroundColor White
Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Info "engine     $($global:ENGINE_EXE)"
Write-Info "python     $($global:PY.Exe) $($global:PY.Pre -join ' ')"
Write-Info "output     $($global:DELIV_DIR)"
$ffversion = (& ffmpeg -version 2>&1 | Select-Object -First 1)
Write-Info "ffmpeg     $ffversion"

Write-Step "checking tools"
Ensure-Tooling
Write-Info "ok: engine, ffmpeg, pillow, ffprobe"

$mode = 'final'
if ($Quick) { $mode = 'preview' }
$ids = @()
if ($Episodes.Count -gt 0) {
    foreach ($e in $Episodes) {
        foreach ($part in ($e -split ',')) {
            $one = $part.Trim()
            if ($one) { $ids += (Get-Episode $one).Id }
        }
    }
} else {
    foreach ($e in $global:EPISODE_DEFS) { $ids += $e.Id }
}
Write-Info ("episodes   " + ($ids -join ', ') + "  [" + $mode + "]")

$results = @()
$index = 0
foreach ($id in $ids) {
    $index++
    $meta = Get-Episode $id
    $proj = Join-Path $global:SERIES_DIR "$id"
    Write-Step ("[{0}/{1}] {2} - {3}  ({4})" -f $index, $ids.Count, $id, $meta.Title, (Format-Duration $meta.Seconds))

    $t0 = Get-Date
    & (Join-Path $PSScriptRoot 'build_episode.ps1') -Episode $id -Mode $mode
    $tBuild = ((Get-Date) - $t0).TotalSeconds

    $t1 = Get-Date
    $renderOut = & (Join-Path $PSScriptRoot 'render.ps1') -ProjectDir $proj 2>&1 | Out-String
    $tRender = ((Get-Date) - $t1).TotalSeconds

    $scene = Join-Path $proj 'project\scene.as'
    $m = Select-String -Path $scene -Pattern '"([^"]*\.mp4)"' | Select-Object -First 1
    $video = Join-Path $proj $m.Matches[0].Groups[1].Value
    $mb = [math]::Round((Get-Item $video).Length / 1MB, 1)

    Write-Info ("built in {0:N0}s, rendered in {1:N0}s, {2} MB" -f $tBuild, $tRender, $mb)
    $results += [pscustomobject]@{ Episode = $id; Title = $meta.Title; Video = $video; MB = $mb; RenderSeconds = [math]::Round($tRender) }
}

if (-not $Quick -and -not $SkipAssemble) {
    Write-Step "mixing audio, cutting thumbnails, building the full series"
    & (Join-Path $PSScriptRoot 'assemble.ps1')
}

$total = ((Get-Date) - $started).TotalSeconds
Write-Step "done"
Write-Host ("    total time : {0:N0}m {1:N0}s" -f [math]::Floor($total / 60), ($total % 60))
$results | ForEach-Object {
    Write-Host ("    {0}  {1,-24} {2,7} MB" -f $_.Episode, $_.Title, $_.MB) -ForegroundColor Gray
}
if (-not $Quick) {
    Write-Host ""
    if ($SkipAssemble) {
        Write-Host "    deliverables were not rebuilt this run (-SkipAssemble)" -ForegroundColor DarkYellow
    } else {
        Write-Host "    deliverables:" -ForegroundColor White
        Get-ChildItem $global:DELIV_DIR -Filter '*.mp4' | Sort-Object Name | ForEach-Object {
            Write-Host ("      {0}  ({1} MB)" -f $_.Name, [math]::Round($_.Length / 1MB, 1)) -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "    open  $($global:DELIV_DIR)" -ForegroundColor White
    }
}


