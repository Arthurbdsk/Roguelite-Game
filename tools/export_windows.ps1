param(
    [string]$Godot = (Join-Path $env:USERPROFILE 'Downloads\Godot_v4.7.2-stable_win64_console.exe'),
    [switch]$Smoke,
    [string]$Output = (Join-Path $PSScriptRoot '..\build\Hordas-0.16.0\Hordas-0.16.0.exe')
)
$ErrorActionPreference = 'Stop'
$exportScript = Join-Path $PSScriptRoot 'export_windows.py'
$exportArguments = @($exportScript, '--godot', $Godot, '--output', $Output)
if ($Smoke) { $exportArguments += '--smoke' }
& python @exportArguments
if ($LASTEXITCODE -ne 0) { throw "Falha na exportação: $LASTEXITCODE" }
