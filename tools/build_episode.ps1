param(
    [Parameter(Mandatory = $true, Position = 0)][string[]]$Episode,
    [ValidateSet('preview', 'final')][string]$Mode = 'preview'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"

foreach ($id in $Episode) {
    $meta = Get-Episode $id
    $scene = Join-Path $global:CONTENT_DIR "$id.as"
    $cards = Join-Path $global:CONTENT_DIR "$id.cards.json"
    if (-not (Test-Path $scene)) { throw "missing scene source: $scene" }
    if (-not (Test-Path $cards)) { throw "missing caption spec: $cards" }

    $proj = Join-Path $global:SERIES_DIR "$id\project"
    New-Item -ItemType Directory -Force -Path $proj, (Join-Path $proj 'textures'), (Join-Path $proj 'renders') | Out-Null
    Copy-Item (Join-Path $global:KIT_DIR 'project\*') $proj -Recurse -Force

    $w = 960; $h = 540; $fps = 30
    if ($Mode -eq 'final') { $w = 1920; $h = 1080; $fps = 60 }
    $cfg = "const int CFG_W = $w;`r`nconst int CFG_H = $h;`r`nconst int CFG_FPS = $fps;`r`n"
    Set-Content -Path (Join-Path $proj 'lib\config.as') -Value $cfg -Encoding ascii
    Copy-Item $scene (Join-Path $proj 'scene.as') -Force

    # previews must never overwrite the 1080p masters
    if ($Mode -eq 'preview') {
        $scenePath = Join-Path $proj 'scene.as'
        $text = Get-Content $scenePath -Raw
        $text = $text -replace '"renders/', '"previews/'
        Set-Content -Path $scenePath -Value $text -Encoding ascii
    }

    Push-Location $global:REPO_ROOT
    try {
        $cardScript = Join-Path $PSScriptRoot 'make_cards.py'
        Invoke-Py $cardScript $cards
    } finally {
        Pop-Location
    }

    Write-Host ("  built {0} [{1}] {2}x{3}@{4}  -  {5}" -f $id, $Mode, $w, $h, $fps, $meta.Title) -ForegroundColor DarkGray
}

