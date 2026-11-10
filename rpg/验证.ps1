param([string]$Godot = (Join-Path $PSScriptRoot '../../../Godot_v4.5.1-stable_win64.exe'))
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$output = Join-Path $workspace 'qa'
$runDir = Join-Path $workspace ('.runtime/rebuild-qa/' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $output,$runDir -Force | Out-Null
$previousAppData = $env:APPDATA
$previousOutput = $env:BOSS_QA_OUTPUT
$env:APPDATA = $runDir
$env:BOSS_QA_OUTPUT = $runDir
$command = '& ./rpg/验证.ps1'
$keys = 'launch','render','input','coreLoop','outcome','restart'
$trace = $null
$code = 1
$reason = ''

try {
    $Godot = (Resolve-Path -LiteralPath $Godot).Path
    $quotedProject = '"' + $PSScriptRoot + '"'
    $import = Start-Process -FilePath $Godot -ArgumentList '--headless','--editor','--path',$quotedProject,'--import' -WindowStyle Hidden -Wait -PassThru
    if ($import.ExitCode -ne 0) { throw 'Godot import failed.' }
    $log = Join-Path $runDir 'godot.log'
    $quotedLog = '"' + $log + '"'
    $game = Start-Process -FilePath $Godot -ArgumentList '--path',$quotedProject,'--resolution','1280x720','--script','res://tests/playthrough.gd','--log-file',$quotedLog -WindowStyle Hidden -PassThru
    if (!$game.WaitForExit(65000)) {
        Stop-Process -Id $game.Id
        throw 'Godot playthrough exceeded its time limit.'
    }
    $code = $game.ExitCode
    if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log }
    $tracePath = Join-Path $runDir 'trace.json'
    if (Test-Path -LiteralPath $tracePath) {
        $trace = Get-Content -LiteralPath $tracePath -Raw -Encoding utf8 | ConvertFrom-Json
        foreach ($frame in $trace.frames) {
            Copy-Item -LiteralPath (Join-Path $runDir $frame) -Destination (Join-Path $output $frame) -Force
        }
    } else {
        $code = 1
        $reason = 'No playthrough trace was written.'
    }
} catch {
    $code = 1
    $reason = $_.Exception.Message
    Write-Warning $reason
} finally {
    $env:APPDATA = $previousAppData
    $env:BOSS_QA_OUTPUT = $previousOutput
}

$checks = [ordered]@{}
$facts = [ordered]@{}
foreach ($key in $keys) {
    $state = if ($trace -and $trace.checks.$key) { $trace.checks.$key } else { 'NOT_RUN' }
    $facts[$key] = $state
    $checks[$key] = @{status=$state; evidence=@('qa/run.json')}
}
if ($code -ne 0) {
    $firstOpen = $keys | Where-Object { $facts[$_] -eq 'NOT_RUN' } | Select-Object -First 1
    if (!$firstOpen) { $firstOpen = 'coreLoop' }
    $facts[$firstOpen] = 'FAIL'
    $checks[$firstOpen].status = 'FAIL'
}
$completeRun = [ordered]@{
    id='native-rebuild'
    cleanContext=$true
    terminal=($(if ($facts.outcome -eq 'PASS') { 'b17-record-reached' } else { 'NOT_REACHED' }))
    restart=($(if ($facts.restart -eq 'PASS') { 'initial-state' } else { 'NOT_RUN' }))
    evidence='qa/run.json'
}
function Write-Record($name, $value) {
    $path = Join-Path $output $name
    $value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath ($path + '.tmp') -Encoding utf8
    Move-Item -LiteralPath ($path + '.tmp') -Destination $path -Force
}
Write-Record 'run.json' ([ordered]@{
    qa=@{command=$command; exitCode=$code; completeRun=$completeRun; checks=$facts}
    runtime=$trace.engine
    renderer=$trace.renderer
    viewport=$trace.viewport
    checkpoints=$trace.checkpoints
    frames=$trace.frames
    error=$reason
})
Write-Record 'verification.json' ([ordered]@{
    schemaVersion=2
    status=($(if ($code -ne 0) {'FAIL'} elseif ($facts.Values -contains 'NOT_RUN') {'NOT_RUN'} else {'PASS'}))
    verify=@{command=$command; exitCode=$code; suites=@('Godot native viewport and injected keyboard/mouse events')}
    completeRun=$completeRun
    checks=$checks
    limitations=@(
        @{scope='输入与画面';reason='Windows Godot 窗口用引擎输入事件完成路径。未测真人输入设备、全屏、不同 DPI 或干净机器。'},
        @{scope='内容与平衡';reason='当前为三场景切片。完整战役、最终 Boss、随机结构、真人节奏和趣味待验证。'}
    )
})
exit $code
