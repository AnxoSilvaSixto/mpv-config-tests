# Chroma rung (real1080): fixed luma zoom-ar + SSim, swap chroma recon.
$M = if ($env:MPV_ROOT) { $env:MPV_ROOT } else { 'C:/mpv' }
$T = Split-Path $PSScriptRoot -Parent
$O = "$M/portable_config/shaders"
$S = "$T/shader-stage"
$C = "$T/clips/real/real1080-dual.mkv"
$H = "$PSScriptRoot/shootout.ps1"
$jobs = @(
    @('ch-cfl', "$O/ravu-zoom-ar-r4.hook,$O/CfL_Prediction.glsl,$O/SSimSuperRes.glsl"),
    @('ch-krig', "$O/ravu-zoom-ar-r4.hook,$S/KrigBilateral.glsl,$O/SSimSuperRes.glsl"),
    @('ch-joint', "$O/ravu-zoom-ar-r4.hook,$S/glsl-joint-bilateral/JointBilateral.glsl,$O/SSimSuperRes.glsl")
)
foreach ($j in $jobs) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $H -Clip $C -Label $j[0] -Chain $j[1]
}
Write-Output 'matrix-chroma done'