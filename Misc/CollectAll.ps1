$outpudDir = "$PSScriptRoot\reshade-shaders";
rmdir $outpudDir -Recurse -Force -ErrorAction Stop
mkdir $outpudDir -ErrorAction SilentlyContinue

$shaderDirs = `
  "$PSScriptRoot\AcerolaFX\Shaders" `
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
, "$PSScriptRoot\Private\ImmersePro\Shaders" `
, "$PSScriptRoot\Private\ImmerseUltimate\Shaders" `
, "$PSScriptRoot\Private\PhysicalDOF\Shaders" `
, "$PSScriptRoot\Private\ReGrade\Shaders" `
, "$PSScriptRoot\Private\ReLight\Shaders" `
, "$PSScriptRoot\Private\RTGI\Shaders" `
, "$PSScriptRoot\Private\YACA22\Shaders" `
, "$PSScriptRoot\Private\qUINT_voxel" `
, "$PSScriptRoot\prod80-ReShade-Repository\Shaders" `
, "$PSScriptRoot\qUINT_master\Shaders" `
, "$PSScriptRoot\qUINT_motionvectors" `
, "$PSScriptRoot\reshade-unity-shaders\Shaders" `
, "$PSScriptRoot\ReshadeMotionEstimation" `
, "$PSScriptRoot\RSRetroArch\Shaders" `
, "$PSScriptRoot\SweetFX\Shaders" `
, "$PSScriptRoot\Vanilla\Shaders" `
, "$PSScriptRoot\YASSGI\Shaders" `
, "$PSScriptRoot\..\Shaders"

$textureDirs = `
  "$PSScriptRoot\AcerolaFX\Textures" `
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
, "$PSScriptRoot\Private\ImmersePro\Textures" `
, "$PSScriptRoot\Private\ImmerseUltimate\Textures" `
, "$PSScriptRoot\Private\ReLight\Textures" `
, "$PSScriptRoot\Private\RTGI\Textures" `
, "$PSScriptRoot\Private\YACA22\Textures" `
, "$PSScriptRoot\prod80-ReShade-Repository\Textures" `
, "$PSScriptRoot\reshade-unity-shaders\Textures" `
, "$PSScriptRoot\RSRetroArch\Textures" `
, "$PSScriptRoot\SweetFX\Textures" `
, "$PSScriptRoot\Vanilla\Textures" `
, "$PSScriptRoot\YASSGI\Textures" `
, "$PSScriptRoot\..\Textures"

function Merge-Links {
    param (
        [string[]] $Folders,
        [string] $Subfolder
    )
    mkdir "$outpudDir\$Subfolder" -ErrorAction SilentlyContinue
    $Folders | ForEach-Object {
        if (Test-Path $_) {
            Write-Output "Processing $_"
            Get-ChildItem $_ | ForEach-Object {
                $target = "$outpudDir\$Subfolder\$($_.Name)";
                if (Test-Path $target) {
                    Write-Warning "$($_.Name) is already linked. Ignoring new one. If they're mismatched this might be a problem";
                }
                else {
                    New-Item -Path $target -ItemType SymbolicLink -Value $_.FullName
                }
            }
        }
        else {
            Write-Warning "$_ input folder didn't exist";
        }
    }
}

Merge-Links $shaderDirs "Shaders"
Merge-Links $textureDirs "Textures"