param([string]$Godot = 'C:/Users/xudic/Desktop/R/Game/Godot_v4.5.1-stable_win64.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$workspaceRoot = Split-Path -Parent $projectRoot
$env:APPDATA = Join-Path $workspaceRoot '.runtime'
New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
$logPath = Join-Path $workspaceRoot 'qa/evidence/mechanisms.log'
'{"status":"NOT_RUN","reason":"本次机制检查尚未完成"}' | Set-Content -LiteralPath (Join-Path $workspaceRoot 'qa/evidence/mechanisms.json') -Encoding utf8
$engineArgs = '--headless --path "{0}" --script res://tests/verify.gd --log-file "{1}"' -f $projectRoot, $logPath
$run = Start-Process -FilePath $Godot -ArgumentList $engineArgs -WindowStyle Hidden -PassThru -Wait
Get-Content -LiteralPath $logPath
$command = '& ./godot/验证.ps1'
$evidenceRoot = Join-Path $workspaceRoot 'qa/evidence'
$sourcePaths = @('main.gd','simulation.gd','main.tscn','project.godot','data/content.json')
$sourceHash = ($sourcePaths | ForEach-Object { (Get-FileHash -LiteralPath (Join-Path $projectRoot $_) -Algorithm SHA256).Hash }) -join '|'
$checks = [ordered]@{}
foreach ($key in @('launch','render','input','coreLoop','outcome','restart')) { $checks[$key] = 'NOT_RUN' }
$uiPath = Join-Path $evidenceRoot 'ui.json'
$uiEvidence = $null
$uiCurrent = $false
if (Test-Path -LiteralPath $uiPath) {
    $uiEvidence = Get-Content -LiteralPath $uiPath -Raw | ConvertFrom-Json
    if ($uiEvidence.sourceHash -eq $sourceHash) {
        $uiCurrent = $true
        foreach ($key in @($checks.Keys)) { $checks[$key] = $uiEvidence.checks.$key }
    }
}
if ($run.ExitCode -ne 0) { $checks['coreLoop'] = 'FAIL'; $checks['outcome'] = 'FAIL' }
$status = if ($checks.Values -contains 'FAIL') { 'FAIL' } elseif ($checks.Values -contains 'NOT_RUN') { 'NOT_RUN' } else { 'PASS' }
$completeRun = [ordered]@{ id='native-smoke'; cleanContext=$true; terminal='NOT_REACHED'; restart=($(if ($checks.restart -eq 'PASS') { 'initial-state' } else { 'NOT_RUN' })); evidence='qa/evidence/run.json' }
if ($uiCurrent -and $uiEvidence.completeRun) { $completeRun = $uiEvidence.completeRun }
$qaFacts = [ordered]@{ command=$command; exitCode=$run.ExitCode; completeRun=$completeRun; checks=$checks }
$record = [ordered]@{ qa=$qaFacts; sourceHash=$sourceHash; mechanisms='qa/evidence/mechanisms.json'; nativeEvidence=$uiEvidence }
$verificationChecks = [ordered]@{}
foreach ($key in $checks.Keys) { $verificationChecks[$key] = @{status=$checks[$key]; evidence=@('qa/evidence/run.json')} }
$verification = [ordered]@{ schemaVersion=2; status=$status; verify=@{command=$command; exitCode=$run.ExitCode; suites=@('机制回归：qa/evidence/mechanisms.json')}; completeRun=$completeRun; checks=$verificationChecks; limitations=@(
    @{scope='实机路径与玩法品质';reason='覆盖范围见当前窗口证据；自动获胜路线不证明真人胜利、平衡或趣味。'},
    @{scope='独立Windows包';reason='对应导出模板及干净机器验收待开展。'},
    @{scope='新Demo与真人节奏';reason='经营、贷款、方针尚未实现；真人完整对局与20–25分钟节奏未验证。'}
) }
function Write-JsonAtomic($path, $value) {
    $value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath ($path + '.tmp') -Encoding utf8
    Move-Item -LiteralPath ($path + '.tmp') -Destination $path -Force
}
Write-JsonAtomic (Join-Path $evidenceRoot 'run.json') $record
Write-JsonAtomic (Join-Path $workspaceRoot 'qa/verification.json') $verification
exit $run.ExitCode
