#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$HalfLifePath = "C:\Program Files (x86)\Steam\steamapps\common\Half-Life",
    [string]$ModDir = "halo_shield",
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $HalfLifePath $ModDir

if ($Build) {
    $msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
    if (-not (Test-Path $msbuild)) {
        $msbuild = (Get-Command MSBuild.exe -ErrorAction SilentlyContinue).Source
        if (-not $msbuild) { throw "MSBuild.exe not found. Install VS C++ workload." }
    }
    & $msbuild "$repoRoot\projects\vs2019\hldll.vcxproj"   -p:Configuration=Release -p:Platform=Win32 -v:minimal -nologo
    if ($LASTEXITCODE -ne 0) { throw "hldll build failed" }
    & $msbuild "$repoRoot\projects\vs2019\hl_cdll.vcxproj" -p:Configuration=Release -p:Platform=Win32 -v:minimal -nologo
    if ($LASTEXITCODE -ne 0) { throw "hl_cdll build failed" }
}

# Note: filecopy.bat (post-build step in vcxproj) already deploys hl.dll + client.dll
# to $target\dlls and $target\cl_dlls. This script syncs everything else under mod/
# (liblist.gam, autoexec.cfg, gfx/shell/kb_act.lst, sounds, sprites, etc.) into
# the installed mod folder.

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Recurse -Force (Join-Path $repoRoot 'mod\*') $target

Write-Host "Deployed mod assets to $target"
Write-Host "If you ran -Build, DLLs were also copied via filecopy.bat post-build step."
