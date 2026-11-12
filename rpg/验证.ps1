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
    $suiteTraces = @()
    foreach ($suite in @('playthrough', 'expedition_playthrough')) {
        $suiteDir = Join-Path $runDir $suite
        New-Item -ItemType Directory -Path $suiteDir -Force | Out-Null
        $env:APPDATA = $suiteDir
        $env:BOSS_QA_OUTPUT = $suiteDir
        $log = Join-Path $suiteDir 'godot.log'
        $quotedLog = '"' + $log + '"'
        $game = Start-Process -FilePath $Godot -ArgumentList '--path',$quotedProject,'--resolution','1280x720','--script',("res://tests/$suite.gd"),'--log-file',$quotedLog -WindowStyle Hidden -PassThru
        if (!$game.WaitForExit(55000)) {
            Stop-Process -Id $game.Id
            throw "Godot $suite exceeded its time limit."
        }
        $code = $game.ExitCode
        if (Test-Path -LiteralPath $log) {
            $logText = Get-Content -LiteralPath $log -Raw
            Write-Output $logText
            if ($logText -match '(SCRIPT ERROR:|ERROR:)') { throw "Godot $suite logged an error." }
        }
        $tracePath = Join-Path $suiteDir 'trace.json'
        if (!(Test-Path -LiteralPath $tracePath)) { throw "No $suite trace was written." }
        $suiteTrace = Get-Content -LiteralPath $tracePath -Raw -Encoding utf8 | ConvertFrom-Json
        $suiteTraces += $suiteTrace
        foreach ($frame in $suiteTrace.frames) {
            Copy-Item -LiteralPath (Join-Path $suiteDir $frame) -Destination (Join-Path $output $frame) -Force
        }
        if ($code -ne 0) { throw "Godot $suite failed." }
    }
    $mergedChecks = [ordered]@{}
    foreach ($key in $keys) {
        $mergedChecks[$key] = if (@($suiteTraces | Where-Object { $_.checks.$key -ne 'PASS' }).Count -eq 0) { 'PASS' } else { 'FAIL' }
    }
    $trace = [pscustomobject]@{
        checks = [pscustomobject]$mergedChecks
        checkpoints = @($suiteTraces | ForEach-Object { $_.checkpoints })
        frames = @($suiteTraces | ForEach-Object { $_.frames })
        engine = $suiteTraces[-1].engine
        renderer = $suiteTraces[-1].renderer
        viewport = $suiteTraces[-1].viewport
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
    id='native-prologue-and-expedition'
    cleanContext=$true
    terminal=($(if ($facts.outcome -eq 'PASS') { 'b17-and-grafted-rearmed-encounter-completed' } else { 'NOT_REACHED' }))
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
    verify=@{command=$command; exitCode=$code; suites=@('Godot native viewport and injected keyboard/mouse events', 'Prologue combat, dodge, hurt and death regression', 'Four-room expedition, graft, shop, persisted stock and rearmed encounter')}
    completeRun=$completeRun
    checks=$checks
    limitations=@(
        @{scope='输入与画面';reason='Windows Godot 窗口用引擎输入事件完成路径。未测真人输入设备、全屏、不同 DPI 或干净机器。'},
        @{scope='内容与平衡';reason='已覆盖原序章、首组四关、一次中心接驳／购物与肺叶入口。其余六组、终极 Boss、长期经济、全部武器组合与真人手感待验证。'}
    )
})
exit $code
