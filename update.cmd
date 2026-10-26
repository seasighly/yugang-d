@echo off
chcp 65001 >nul
REM YuGangD updater entry
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
pause
