param([string]$Godot = 'C:/Users/xudic/Desktop/R/Game/Godot_v4.5.1-stable_win64.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw '请通过 -Godot 指定本机 Godot 4.5.1 可执行文件。' }
Start-Process -FilePath $Godot -ArgumentList ('--path "{0}"' -f $PSScriptRoot)
