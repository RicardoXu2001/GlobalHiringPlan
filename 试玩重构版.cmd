@echo off
setlocal
set "GODOT_EXE=%~dp0..\..\Godot_v4.5.1-stable_win64.exe"
if not exist "%GODOT_EXE%" (
  echo Godot 4.5.1 was not found. Open rpg/project.godot in Godot.
  pause
  exit /b 1
)
if not exist "%~dp0rpg\.godot\imported\" (
  start "" /wait "%GODOT_EXE%" --headless --editor --path "%~dp0rpg" --import
  if errorlevel 1 (
    echo Asset import failed. Open rpg/project.godot in the editor to inspect the import.
    pause
    exit /b 1
  )
)
start "" "%GODOT_EXE%" --path "%~dp0rpg"
