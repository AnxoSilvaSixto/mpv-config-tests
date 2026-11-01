<#
Shader chain stability: four consecutive 4K HDR files through the real config
must keep glsl-shaders at the intended 7 entries (Res-Downscale + bt.2100-pq)
with no duplicated paths. Guards the profile-restore=copy re-append bug.
Exit 0 = all checks pass.
#>
$ErrorActionPreference = 'Stop'
$root = if ($env:MPV_ROOT) { $env:MPV_ROOT } else { 'C:/mpv' }
$mpv = Join-Path $root 'mpv.exe'   # .exe directly, never the .com wrapper
$clip = Join-Path $PSScriptRoot 'clips/real/real2160-pq.mkv'
if (-not (Test-Path $clip)) { throw "missing clip: $clip" }
$fail = 0
function Check($name, $cond) {
    if ($cond) { Write-Output "PASS: $name" } else { Write-Output "FAIL: $name"; $script:fail++ }
}

$pipeName = 'mpv-shaderchain-test'
$log = Join-Path $env:TEMP 'mpv-test-shaderchain.log'
$wl = Join-Path $env:TEMP 'mpv-test-shaderchain-wl'
Remove-Item $log -ErrorAction SilentlyContinue
Remove-Item $wl -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $wl | Out-Null

$proc = Start-Process $mpv -ArgumentList @(
    $clip, $clip, $clip, $clip,
    '--keep-open=no', '--no-autocreate-playlist', '--no-resume-playback', '--length=2',
    '--vo=null', '--ao=null', '--force-window=no', '--no-terminal',
    "--watch-later-dir=$wl",
    "--input-ipc-server=$pipeName",
    "--log-file=$log",
    '--msg-level=cplayer=v,utilities=v'
) -PassThru -WindowStyle Hidden -RedirectStandardOutput NUL

try {
    $pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.', $pipeName, [System.IO.Pipes.PipeDirection]::InOut)
    $pipe.Connect(15000)
    $w = New-Object System.IO.StreamWriter($pipe); $w.AutoFlush = $true
    $r = New-Object System.IO.StreamReader($pipe)
    $chains = @()
    $deadline = (Get-Date).AddSeconds(90)
    while ((Get-Date) -lt $deadline -and $chains.Count -lt 4 -and -not $proc.HasExited) {
        $line = $r.ReadLine()
        if ($line -match '"event":"playback-restart"') {
            # Let the playback-restart script handlers (shader-dedup) finish first.
            Start-Sleep -Milliseconds 500
            $w.WriteLine('{ "command": ["get_property", "glsl-shaders"] }')
            $reply = $null
            while ($null -eq $reply) {
                $candidate = $r.ReadLine()
                if ($candidate -match '"request_id"') { $reply = $candidate }
            }
            $paths = @([regex]::Matches($reply, '"(~~/[^"]+)"') | ForEach-Object { $_.Groups[1].Value })
            $chains += ,$paths
        }
    }
    $w.WriteLine('{ "command": ["quit"] }')
    $pipe.Close()
    $proc.WaitForExit(15000) | Out-Null
} finally {
    if (-not $proc.HasExited) { $proc.Kill() }
    Remove-Item $wl -Recurse -Force -ErrorAction SilentlyContinue
}

Check 'four playback-restart samples captured' ($chains.Count -eq 4)
for ($i = 0; $i -lt $chains.Count; $i++) {
    $paths = @($chains[$i])
    $unique = @($paths | Sort-Object -Unique).Count
    Check ("file {0}: chain has 7 shaders" -f ($i + 1)) (($paths.Count -eq 7) -and ($unique -eq 7))
}
$text = Get-Content $log -Raw
Check 'dedup corrected file 2 (9 -> 7)' ($text -match 'shader-dedup: 9 -> 7')
Check 'dedup corrected file 3 (11 -> 7)' ($text -match 'shader-dedup: 11 -> 7')
Check 'dedup corrected file 4 (13 -> 7)' ($text -match 'shader-dedup: 13 -> 7')
Check 'shaderchain log clean' (-not ($text -match '\[fatal\]|\[error\]|lua error'))
exit $fail
