param(
    [Parameter(Mandatory=$true)][string]$ProjectDir,
    [string]$Exe = 'C:\Users\Cosmos\Documents\GitHub\Explain_DDRAM_Visuals_V0\TheNewStatelessPointcloudEngine_V1_Runtime\engine.exe'
)
$ErrorActionPreference = 'Stop'
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);'
Get-Process engine -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
$log = Join-Path ([System.IO.Path]::GetTempPath()) ("check_" + [guid]::NewGuid().ToString('N') + ".log")
$proc = Start-Process -FilePath $Exe -WorkingDirectory $ProjectDir -PassThru -WindowStyle Minimized -RedirectStandardOutput $log -RedirectStandardError ($log + '.err')
$sw = [System.Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 10) {
    if ($proc.HasExited) { break }
    $proc.Refresh()
    if ($proc.MainWindowTitle -like 'Stateless Pointcloud World*') { break }
    if ((Test-Path $log) -and ((Get-Item $log).Length -gt 300)) { Start-Sleep -Milliseconds 700; break }
    Start-Sleep -Milliseconds 200
}
$out = ''
foreach ($f in @($log, ($log + '.err'))) { if (Test-Path $f) { $out += (Get-Content $f -Raw -ErrorAction SilentlyContinue) } }
if (-not $proc.HasExited) { [void][W.U]::PostMessage($proc.MainWindowHandle, 0x0010, [IntPtr]0, [IntPtr]0); Start-Sleep -Milliseconds 2500; if (-not $proc.HasExited) { $proc.Kill() } }
Start-Sleep -Milliseconds 300
$out

