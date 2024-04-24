$outpudDir = "$PSScriptRoot\reshade-shaders";
Remove-Item $outpudDir -Recurse -Force -ErrorAction Stop
mkdir $outpudDir -ErrorAction SilentlyContinue

$shaderDirs = `
  "$PSScriptRoot\..\Shaders" `
, "$PSScriptRoot\Vanilla\Shaders" `
, "$PSScriptRoot\AcerolaFX\Shaders" `
, "$PSScriptRoot\AgXc\reshade\reshade-shaders\Shaders" `
, "$PSScriptRoot\AstrayFX\Shaders" `
, "$PSScriptRoot\brussell1\Shaders" `
, "$PSScriptRoot\CobraFX\Shaders" `
, "$PSScriptRoot\CShade\Shaders" `
, "$PSScriptRoot\crt-royale-reshade\reshade-shaders\Shaders" `
, "$PSScriptRoot\Daodan\Shaders" `
, "$PSScriptRoot\fubax-shaders\Shaders" `
, "$PSScriptRoot\iMMERSE\Shaders" `
, "$PSScriptRoot\Insane-Shaders\Shaders" `
, "$PSScriptRoot\Luluco250_FXShaders\Shaders" `
, "$PSScriptRoot\METEOR\Shaders" `
, "$PSScriptRoot\NiceGuy-Shaders\Shaders" `
, "$PSScriptRoot\OtisFX\Shaders" `
, "$PSScriptRoot\Private\ImmerseUltimate\Shaders" `
, "$PSScriptRoot\qUINT_motionvectors" `
, "$PSScriptRoot\prod80-ReShade-Repository\Shaders" `
, "$PSScriptRoot\reshade-unity-shaders\Shaders" `
, "$PSScriptRoot\ReshadeMotionEstimation" `
, "$PSScriptRoot\RSRetroArch\Shaders" `
, "$PSScriptRoot\SweetFX\Shaders" `
, "$PSScriptRoot\YASSGI\Shaders"

$textureDirs = `
  "$PSScriptRoot\..\Textures" `
, "$PSScriptRoot\Vanilla\Textures" `
, "$PSScriptRoot\AcerolaFX\Textures" `
, "$PSScriptRoot\AgXc\reshade\reshade-shaders\Textures" `
, "$PSScriptRoot\AstrayFX\Textures" `
, "$PSScriptRoot\brussell1\Textures" `
, "$PSScriptRoot\CobraFX\Textures" `
, "$PSScriptRoot\Daodan\Textures" `
, "$PSScriptRoot\fubax-shaders\Textures" `
, "$PSScriptRoot\iMMERSE\Textures" `
, "$PSScriptRoot\Luluco250_FXShaders\Textures" `
, "$PSScriptRoot\METEOR\Textures" `
, "$PSScriptRoot\NiceGuy-Shaders\Textures" `
, "$PSScriptRoot\OtisFX\Textures" `
, "$PSScriptRoot\Private\ImmerseUltimate\Textures" `
, "$PSScriptRoot\prod80-ReShade-Repository\Textures" `
, "$PSScriptRoot\reshade-unity-shaders\Textures" `
, "$PSScriptRoot\RSRetroArch\Textures" `
, "$PSScriptRoot\SweetFX\Textures" `
, "$PSScriptRoot\YASSGI\Textures"

function Merge-Links {
    param (
        [string[]] $Folders,
        [string] $Output
    )
    mkdir $Output -ErrorAction SilentlyContinue
    $Folders | ForEach-Object {
        if (Test-Path $_) {
            Write-Output "Processing $_"
            Get-ChildItem $_ -File | ForEach-Object {
                $target = "$Output\$($_.Name)";
                if (Test-Path $target) {
                    Write-Warning "$($_.Name) is already linked. Ignoring new one. If they're mismatched this might be a problem";
                }
                else {
                    New-Item -Path $target -ItemType SymbolicLink -Value $_.FullName
                }
            }
            Get-ChildItem $_ -Directory | ForEach-Object {
                Merge-Links $_.FullName "$Output\$($_.Name)"
            }
        }
        else {
            Write-Warning "$_ input folder didn't exist";
        }
    }
}

Merge-Links $shaderDirs "$outpudDir\Shaders"
Merge-Links $textureDirs "$outpudDir\Textures"