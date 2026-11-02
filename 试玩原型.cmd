@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\Godot_v4.5.1-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot 4.5.1 was not found. Import godot/project.godot in Godot or see godot/README.md.
  pause
  exit /b 1
)
start "" "%GODOT_EXE%" --path "%~dp0godot"
