param(
    [switch]$SkipSeries,
    [switch]$SkipIntro
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

Ensure-Tooling

$thumbTimes = @{
    ep01 = @(9, 23, 37)
    ep02 = @(20, 27, 12)
    ep03 = @(16, 30, 8)
    ep04 = @(18, 28, 33)
    ep05 = @(17, 32, 9)
    ep06 = @(16, 25, 34)
}

function Get-EpisodeRender([string]$id) {
    $scene = Join-Path $global:SERIES_DIR "$id\project\scene.as"
    if (-not (Test-Path $scene)) { throw "project for $id not built yet (run tools\build_episode.ps1 -Episode $id -Mode final)" }
    $m = Select-String -Path $scene -Pattern '"([^"]*\.mp4)"' | Select-Object -First 1
    if (-not $m) { throw "could not find the video output path in $scene" }
    $rel = $m.Matches[0].Groups[1].Value
    $path = Join-Path (Join-Path $global:SERIES_DIR "$id") $rel
    if (-not (Test-Path $path)) { throw "render for $id not found at $path - run generate_video.bat first" }
    $probe = & ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 $path 2>$null
    if ($probe -and [int]$probe -lt 1920) {
        throw "the render for $id is only ${probe}px wide (a preview). Rebuild it at final quality: generate_video.bat -Episodes $id"
    }
    return $path
}

function Ensure-Audio([int]$seconds, [int]$seed) {
    $bed = Join-Path $global:AUDIO_DIR ("amb_{0}.wav" -f $seconds)
    if (-not (Test-Path $bed)) {
        $audioScript = Join-Path $PSScriptRoot 'make_audio.py'
        $secArg = "$seconds"
        $seedArg = "$seed"
        Invoke-Py $audioScript $bed $secArg $seedArg
    }
    return $bed
}

# ---------------------------------------------------------------- intro bumper
$muxed = @()
if (-not $SkipIntro) {
    $introPng = Join-Path $global:AUDIO_DIR 'intro.png'
    $introScript = Join-Path $PSScriptRoot 'make_intro.py'
    Invoke-Py $introScript $introPng
    $introMp4 = Join-Path $global:DELIV_DIR 'DRAM_Explained_Intro_1080p60.mp4'
    & ffmpeg -hide_banner -loglevel error -y -loop 1 -i $introPng `
        -f lavfi -t 4.2 -i "anullsrc=channel_layout=stereo:sample_rate=44100" `
        -t 4.2 -r 60 `
        -vf "zoompan=z='min(1.0+0.00035*on,1.06)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1920x1080:fps=60,fade=t=in:st=0:d=0.7,fade=t=out:st=3.4:d=0.8,format=yuv420p" `
        -c:v libx264 -preset medium -crf 20 -c:a aac -b:a 128k -shortest $introMp4
    if ($LASTEXITCODE -ne 0) { throw "intro render failed" }
    $muxed += $introMp4
    Write-Host "  intro bumper   -> $introMp4" -ForegroundColor DarkGray
}

# ------------------------------------------------------------------- episodes
$i = 0
foreach ($ep in $global:EPISODE_DEFS) {
    $i++
    $src = Get-EpisodeRender $ep.Id
    $bed = Ensure-Audio $ep.Seconds $i
    $dst = Join-Path $global:DELIV_DIR ("DRAM_Explained_EP{0}_{1}_1080p60.mp4" -f $ep.Id.Substring(2), $ep.Slug)

    & ffmpeg -hide_banner -loglevel error -y -i $src -i $bed `
        -filter:a "volume=0.55" -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p -movflags +faststart `
        -c:a aac -b:a 128k -shortest $dst
    if ($LASTEXITCODE -ne 0) { throw "mux failed for $($ep.Id)" }
    $muxed += $dst
    $mb = [math]::Round((Get-Item $dst).Length / 1MB, 1)
    Write-Host ("  {0}  {1,-24} {2,6} MB  {3}" -f $ep.Id, $ep.Title, $mb, (Split-Path $dst -Leaf)) -ForegroundColor DarkGray

    foreach ($t in $thumbTimes[$ep.Id]) {
        $thumb = Join-Path $global:DELIV_DIR ("thumbnails\EP{0}_t{1:000}.png" -f $ep.Id.Substring(2), [int]$t)
        & ffmpeg -hide_banner -loglevel error -y -ss $t -i $dst -frames:v 1 $thumb
    }
    $poster = Join-Path $global:DELIV_DIR ("posters\EP{0}_{1}_poster.png" -f $ep.Id.Substring(2), $ep.Slug)
    & ffmpeg -hide_banner -loglevel error -y -ss $thumbTimes[$ep.Id][0] -i $dst -frames:v 1 $poster
}

# --------------------------------------------------------------- full series
if (-not $SkipSeries -and $muxed.Count -gt 1) {
    $list = Join-Path $global:WORK_DIR 'concat.txt'
    Set-Content -Path $list -Value (($muxed | ForEach-Object { "file '$($_ -replace '\\', '/')'" })) -Encoding ascii
    $series = Join-Path $global:DELIV_DIR 'DRAM_Explained_Full_Series_1080p60.mp4'
    & ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i $list -c copy -movflags +faststart $series
    if ($LASTEXITCODE -ne 0) { throw "series concatenation failed" }
    Write-Host ("  full series    -> {0} ({1} MB)" -f (Split-Path $series -Leaf), [math]::Round((Get-Item $series).Length / 1MB, 1)) -ForegroundColor DarkGray
}

# ------------------------------------------------------------- contact sheet
$posters = Get-ChildItem (Join-Path $global:DELIV_DIR 'posters') -Filter 'EP*_poster.png' | Sort-Object Name
if ($posters.Count -eq 6) {
    $ffargs = @()
    foreach ($p in $posters) { $ffargs += @('-i', $p.FullName) }
    $filter = ''
    for ($k = 0; $k -lt 6; $k++) { $filter += ('[{0}:v]scale=640:360[v{0}];' -f $k) }
    $filter += '[v0][v1][v2][v3][v4][v5]xstack=inputs=6:layout=0_0|640_0|1280_0|0_360|640_360|1280_360[out]'
    $ffargs += @('-filter_complex', $filter, '-map', '[out]', '-frames:v', '1', (Join-Path $global:DELIV_DIR 'posters\SERIES_CONTACT_SHEET.png'))
    & ffmpeg -hide_banner -loglevel error -y @ffargs
    Write-Host "  contact sheet  -> posters\SERIES_CONTACT_SHEET.png" -ForegroundColor DarkGray
}


