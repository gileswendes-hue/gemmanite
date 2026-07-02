@echo off
title Gemmanite playlist sync
echo Syncing Spotify playlist once, then publishing if changed...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\sync-playlist-once.ps1"
pause
