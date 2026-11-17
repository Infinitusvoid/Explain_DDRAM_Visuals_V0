param(
    [Parameter(Mandatory = $true, Position = 0)][string]$ProjectDir,
    [string]$OutMp4 = '',
    [int]$TimeoutSec = 2400,
    [string]$Exe = '',
    [int]$Attempts = 3,
    [switch]$ShowWindow
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
if (-not $Exe) { Ensure-Engine; $Exe = $global:ENGINE_EXE }

if (-not ("EngineWin" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class EngineWin
{
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);

    // The engine's real render window; its console is a decoy and often becomes the
    // process "main window", so locate the GL window by class and title instead.
    public static IntPtr FindRenderWindow(uint pid, bool needScene)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows((h, l) =>
        {
            uint p;
            GetWindowThreadProcessId(h, out p);
            if (p != pid) return true;
            var cls = new StringBuilder(256);
            GetClassName(h, cls, 256);
            if (cls.ToString() != "P1_Engine_Internal_OpenGL_Window") return true;
            var title = new StringBuilder(512);
            GetWindowText(h, title, 512);
            string t = title.ToString();
            if (!t.StartsWith("Stateless Pointcloud World")) return true;
            if (needScene && t.IndexOf("logical points") < 0) return true;
            found = h;
            return false;
        }, IntPtr.Zero);
        return found;
    }
}
'@
}

function Stop-Engines {
    Get-Process engine -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill() } catch {} }
    for ($i = 0; $i -lt 40; $i++) {
        if (-not (Get-Process engine -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 100
    }
    Start-Sleep -Milliseconds 700
}

function Read-Log([string]$path) {
    $t = ''
    foreach ($f in @($path, ($path + '.err'))) {
        if (Test-Path $f) { $t += (Get-Content $f -Raw -ErrorAction SilentlyContinue) }
    }
    return $t
}

function Post-F9([IntPtr]$hwnd) {
    [void][EngineWin]::PostMessage($hwnd, 0x0100, [IntPtr]0x78, [IntPtr]0x00000001)
    Start-Sleep -Milliseconds 90
    [void][EngineWin]::PostMessage($hwnd, 0x0101, [IntPtr]0x78, [IntPtr]([int64]0xC0000001))
}

# The engine renders to the path declared in the project's scene.as.
if (-not $OutMp4) {
    $scene = Join-Path $ProjectDir 'project\scene.as'
    $m = Select-String -Path $scene -Pattern '"([^"]*\.mp4)"' | Select-Object -First 1
    if (-not $m) { throw "could not find the video output path in $scene" }
    $OutMp4 = $m.Matches[0].Groups[1].Value
}
$full = if ([System.IO.Path]::IsPathRooted($OutMp4)) { $OutMp4 } else { Join-Path $ProjectDir $OutMp4 }
$full = [System.IO.Path]::GetFullPath($full)

$lastError = ''
for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
    Stop-Engines
    if (Test-Path $full) { Remove-Item $full -Force }

    $log = Join-Path ([System.IO.Path]::GetTempPath()) ("engine_" + [guid]::NewGuid().ToString('N') + ".log")
    $proc = Start-Process -FilePath $Exe -WorkingDirectory $ProjectDir -PassThru -WindowStyle Minimized -RedirectStandardOutput $log -RedirectStandardError ($log + ".err")

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $hwnd = [IntPtr]::Zero
    $rejected = $false
    while ($sw.Elapsed.TotalSeconds -lt 60) {
        if ($proc.HasExited) { break }
        $hwnd = [EngineWin]::FindRenderWindow([uint32]$proc.Id, $true)
        if ($hwnd -ne [IntPtr]::Zero) { break }
        $t = Read-Log $log
        if ($t -match '(?i)Project initialization failed|AngelScript compile failed|Shader compilation failed') {
            Start-Sleep -Milliseconds 600
            $lastError = "attempt ${attempt}: project rejected. log=" + $t.Trim()
            $rejected = $true
            break
        }
        Start-Sleep -Milliseconds 200
    }

    if ($rejected -or $hwnd -eq [IntPtr]::Zero) {
        if ($hwnd -eq [IntPtr]::Zero -and -not $rejected) {
            $lastError = "attempt ${attempt}: no render window. log=" + ((Read-Log $log).Trim())
        }
        if (-not $proc.HasExited) { $proc.Kill() }
        Start-Sleep -Milliseconds 800
        continue
    }

    if (-not $ShowWindow) { [void][EngineWin]::ShowWindow($hwnd, 6) }   # minimize, never activate
    Start-Sleep -Milliseconds 900

    $posted = 0
    $started = $false
    while ($posted -lt 5 -and -not $started) {
        if ($proc.HasExited) { break }
        Post-F9 $hwnd
        $posted++
        Start-Sleep -Milliseconds 1500
        if (Get-Process ffmpeg -ErrorAction SilentlyContinue) { $started = $true }
        if (Test-Path $full) { $started = $true }
    }

    $success = $false
    $lastSize = -1
    $stableSince = $null
    $deadline = $sw.Elapsed.TotalSeconds + $TimeoutSec
    while ($sw.Elapsed.TotalSeconds -lt $deadline) {
        Start-Sleep -Milliseconds 1000
        if ($proc.HasExited) { break }
        if (Test-Path $full) {
            $size = (Get-Item $full).Length
            if ($size -ne $lastSize) { $lastSize = $size; $stableSince = $sw.Elapsed.TotalSeconds }
            elseif ($null -ne $stableSince -and ($sw.Elapsed.TotalSeconds - $stableSince) -gt 6 -and $size -gt 1000 -and -not (Get-Process ffmpeg -ErrorAction SilentlyContinue)) {
                $success = $true
                break
            }
        }
    }

    $elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    if ($success) {
        $probe = & ffprobe -v error -select_streams v:0 -show_entries stream=width,height,nb_frames,r_frame_rate -of csv=p=0 $full 2>$null
        if (-not $proc.HasExited) { $proc.Kill() }
        [pscustomobject]@{
            Output  = $full
            MBytes  = [math]::Round((Get-Item $full).Length / 1MB, 1)
            Seconds = $elapsed
            Probe   = ($probe -join ' ')
            Attempt = $attempt
        } | Format-List
        return
    }

    $lastError = "attempt ${attempt}: render not produced after ${elapsed}s; f9posts=$posted log=" + ((Read-Log $log).Trim())
    if (-not $proc.HasExited) { $proc.Kill() }
    Start-Sleep -Milliseconds 800
}

Stop-Engines
throw "Render failed. $lastError"
