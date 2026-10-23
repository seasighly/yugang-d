@echo off
chcp 65001 >nul
REM YuGangD installer entry
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
pause
