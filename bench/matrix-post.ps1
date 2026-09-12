# Post rung (real720): fixed ArtCNN32 + CfL, swap post-resize pass.
$M = if ($env:MPV_ROOT) { $env:MPV_ROOT } else { 'C:/mpv' }
$T = Split-Path $PSScriptRoot -Parent
$O = "$M/portable_config/shaders"
$S = "$T/shader-stage"
$C = "$T/clips/real/real720-av1.mkv"
$H = "$PSScriptRoot/shootout.ps1"
$jobs = @(
    @('post-ssim', "$O/ArtCNN_C4F32.glsl,$O/CfL_Prediction.glsl,$O/SSimSuperRes.glsl"),
    @('post-adap', "$O/ArtCNN_C4F32.glsl,$O/CfL_Prediction.glsl,$S/MPV-Custom-Shaders/adaptive-sharpen.glsl"),
    @('post-none', "$O/ArtCNN_C4F32.glsl,$O/CfL_Prediction.glsl")
)
foreach ($j in $jobs) {
    powershell -NoProfile -ExecutionPolicy Bypass -File $H -Clip $C -Label $j[0] -Chain $j[1]
}
Write-Output 'matrix-post done'