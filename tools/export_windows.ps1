param(
    [string]$Godot = (Join-Path $env:USERPROFILE 'Downloads\Godot_v4.7.2-stable_win64_console.exe'),
    [switch]$Smoke
)
$ErrorActionPreference = 'Stop'
$exportScript = Join-Path $PSScriptRoot 'export_windows.py'
$exportArguments = @($exportScript, '--godot', $Godot)
if ($Smoke) { $exportArguments += '--smoke' }
& python @exportArguments
if ($LASTEXITCODE -ne 0) { throw "Falha na exportação: $LASTEXITCODE" }
