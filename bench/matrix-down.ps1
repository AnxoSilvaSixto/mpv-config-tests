# Downscale rung (real2160 -> 1440p out): with/without SSimDownscaler.
$M = if ($env:MPV_ROOT) { $env:MPV_ROOT } else { 'C:/mpv' }
$T = Split-Path $PSScriptRoot -Parent
$O = "$M/portable_config/shaders"
$C = "$T/clips/real/real2160-pq.mkv"
$H = "$PSScriptRoot/shootout.ps1"
$jobs = @(
    @('dn-ssim', "$O/SSimDownscaler.glsl"),
    @('dn-none', "")
)
foreach ($j in $jobs) {
    if ($j[1] -eq "") {
        powershell -NoProfile -ExecutionPolicy Bypass -File $H -Clip $C -Label $j[0]
    } else {
        powershell -NoProfile -ExecutionPolicy Bypass -File $H -Clip $C -Label $j[0] -Chain $j[1]
    }
}
Write-Output 'matrix-down done'