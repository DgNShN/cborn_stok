@echo off
setlocal EnableDelayedExpansion

cd /d "%~dp0"

REM ============================================================
REM Flutter Windows: MSVC ortami + Ninja generator
REM VS "Visual Studio generator" ozel yoldaki VS'yi bulamiyor;
REM Ninja generator CC/CXX degiskenlerini okuyor.
REM ============================================================

set "PF86=%ProgramFiles(x86)%"
set "VSWHERE=%PF86%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSOUT=%TEMP%\cborn_vs_path_%RANDOM%.txt"

if defined CBORN_VS_INSTALL goto use_cborn
if not exist "%VSWHERE%" goto err_vswhere

"%VSWHERE%" -latest -products * -property installationPath > "%VSOUT%" 2>nul
set "VSINSTALLDIR="
if exist "%VSOUT%" for /f "usebackq delims=" %%i in ("%VSOUT%") do set "VSINSTALLDIR=%%i"
del "%VSOUT%" 2>nul
goto have_vs

:use_cborn
set "VSINSTALLDIR=%CBORN_VS_INSTALL%"

:have_vs
if not defined VSINSTALLDIR goto err_no_vs
echo Visual Studio: !VSINSTALLDIR!

REM --- MSVC ---
set "MSVC_BASE=!VSINSTALLDIR!\VC\Tools\MSVC"
if not exist "!MSVC_BASE!" goto err_msvc

set "MSVC_VER="
for /f "delims=" %%v in ('dir /b /ad /o-n "!MSVC_BASE!" 2^>nul') do (
  set "MSVC_VER=%%v"
  goto msvc_got
)
:msvc_got
if not defined MSVC_VER goto err_msvc

set "MSVC_FULL=!MSVC_BASE!\!MSVC_VER!"
set "MSVC_BIN=!MSVC_FULL!\bin\Hostx64\x64"
if not exist "!MSVC_BIN!\cl.exe" goto err_msvc

REM --- Windows SDK ---
set "KIT_ROOT=!PF86!\Windows Kits\10"
set "KIT_INC=!KIT_ROOT!\Include"
if not exist "!KIT_INC!" goto err_sdk
set "SDK_VER="
for /f "delims=" %%s in ('dir /b /ad /o-n "!KIT_INC!" 2^>nul') do (
  set "SDK_VER=%%s"
  goto sdk_got
)
:sdk_got
if not defined SDK_VER goto err_sdk

set "KIT_LIB=!KIT_ROOT!\Lib\!SDK_VER!"
set "KIT_BIN=!KIT_ROOT!\bin\!SDK_VER!\x64"

REM --- Ninja ---
set "NINJA_DIR=!VSINSTALLDIR!\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
if not exist "!NINJA_DIR!\ninja.exe" goto err_ninja

REM --- CMAKE (VS ile gelen) ---
set "CMAKE_VS=!VSINSTALLDIR!\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"

REM --- PATH ---
set "PATH=!MSVC_BIN!;!KIT_BIN!;!NINJA_DIR!;!CMAKE_VS!;%PATH%"

REM --- INCLUDE / LIB ---
set "INCLUDE=!MSVC_FULL!\include;!KIT_INC!\!SDK_VER!\ucrt;!KIT_INC!\!SDK_VER!\shared;!KIT_INC!\!SDK_VER!\um;!KIT_INC!\!SDK_VER!\winrt"
set "LIB=!MSVC_FULL!\lib\x64;!KIT_LIB!\ucrt\x64;!KIT_LIB!\um\x64"
set "LIBPATH=!MSVC_FULL!\lib\x64"

REM --- CMake / derleyici degiskenleri ---
set "CC=!MSVC_BIN!\cl.exe"
set "CXX=!MSVC_BIN!\cl.exe"
set "CMAKE_C_COMPILER=!MSVC_BIN!\cl.exe"
set "CMAKE_CXX_COMPILER=!MSVC_BIN!\cl.exe"
set "CMAKE_GENERATOR=Ninja"
set "CMAKE_MAKE_PROGRAM=!NINJA_DIR!\ninja.exe"

REM --- VS degiskenleri ---
set "VCToolsInstallDir=!MSVC_FULL!\"
set "VCToolsVersion=!MSVC_VER!"
set "WindowsSdkDir=!KIT_ROOT!\"
set "WindowsSDKVersion=!SDK_VER!\"
set "UniversalCRTSdkDir=!KIT_ROOT!\"
set "UCRTVersion=!SDK_VER!"
set "VSCMD_VER=!MSVC_VER!"

echo MSVC: !MSVC_VER!
echo SDK:  !SDK_VER!
echo Ninja: !NINJA_DIR!\ninja.exe
echo Generator: Ninja

where cl >nul 2>&1
if errorlevel 1 goto err_cl

echo cl.exe: OK
where cl
echo.

REM --- Eski build temizle ---
if exist "build\windows" (
  echo Eski Windows build siliniyor...
  rmdir /s /q "build\windows"
)

echo Proje: %CD%
echo Flutter baslatiliyor...
echo.

flutter run -d windows %*
set "EX=!ERRORLEVEL!"
if not "!EX!"=="0" pause
exit /b !EX!

:err_vswhere
echo [HATA] vswhere bulunamadi: %VSWHERE%
pause & exit /b 1

:err_no_vs
echo [HATA] Visual Studio bulunamadi.
pause & exit /b 1

:err_msvc
echo [HATA] MSVC bulunamadi: !MSVC_BASE!
pause & exit /b 1

:err_sdk
echo [HATA] Windows SDK bulunamadi: !KIT_ROOT!
pause & exit /b 1

:err_ninja
echo [HATA] ninja.exe bulunamadi: !NINJA_DIR!
pause & exit /b 1

:err_cl
echo [HATA] cl.exe PATH'te yok.
pause & exit /b 1
