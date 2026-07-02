@echo off
title Gemmanite playlist poller
echo Polling Spotify playlist every 15 minutes. Close this window to stop.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\poll-playlist.ps1"
pause
