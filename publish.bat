@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\publish.ps1" %*
if errorlevel 1 pause
