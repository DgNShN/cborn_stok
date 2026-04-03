# Flutter Windows: MSVC ortami (batch hata verirse dene)
# PowerShell: sag tik -> PowerShell ile calistir
# veya: powershell -ExecutionPolicy Bypass -File run_windows.ps1

$ErrorActionPreference = "Stop"
$pf86 = ${env:ProgramFiles(x86)}
$vsWhere = Join-Path $pf86 "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vsWhere)) {
    Write-Host "[HATA] vswhere yok: $vsWhere"
    exit 1
}

$vsPath = & $vsWhere -latest -products * -property installationPath | Select-Object -First 1
if (-not $vsPath) {
    Write-Host "[HATA] Visual Studio bulunamadi."
    exit 1
}

Write-Host "Visual Studio: $vsPath"
$devShell = Join-Path $vsPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
if (-not (Test-Path $devShell)) {
    Write-Host "[HATA] DevShell.dll yok: $devShell"
    exit 1
}

Import-Module $devShell
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"

Set-Location $PSScriptRoot
$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
if (-not $cl) {
    Write-Host "[HATA] cl.exe bulunamadi. Visual Studio Installer -> Onar."
    exit 1
}
Write-Host "cl.exe: OK - $($cl.Source)"
Write-Host "Proje: $(Get-Location)"
flutter run -d windows @args
