@echo off
setlocal
title How DRAM Works - video generator
cd /d "%~dp0"

if /i "%~1"=="/?" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--help" goto usage
if /i "%~1"=="/help" goto usage

echo.
echo  ===========================================================
echo   HOW DRAM WORKS  -  generate every episode + the full series
echo  ===========================================================
echo.

where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo  [ERROR] FFmpeg was not found on PATH.
  echo          Install it with:  winget install Gyan.FFmpeg
  echo          then close this window, open a new one and run this file again.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\generate_all.ps1" %*
set RC=%ERRORLEVEL%

echo.
if not "%RC%"=="0" (
  echo  ===========================================================
  echo   FAILED with exit code %RC%
  echo   Scroll up for the first error message.
  echo  ===========================================================
) else (
  echo  ===========================================================
  echo   Finished.  Videos land in the "deliverables" folder.
  echo  ===========================================================
)
echo.
pause
exit /b %RC%

:usage
echo.
echo  HOW DRAM WORKS  -  video generator
echo.
echo  Usage:
echo    generate_video.bat                     all six episodes + full series
echo    generate_video.bat -Quick              fast 960x540 previews (no deliverables)
echo    generate_video.bat -Episodes ep03      rebuild only the listed episodes
echo    generate_video.bat -Episodes ep03,ep05 rebuild a few (comma separated)
echo    generate_video.bat -SkipAssemble       re-render episodes only
echo.
echo  Output:  deliverables\  (videos, posters, thumbnails, README)
echo  Requires FFmpeg on PATH and Python 3 with Pillow.
echo.
pause
exit /b 0
