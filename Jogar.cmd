@echo off
if exist "%~dp0build\Hordas-0.21.0\Hordas-0.21.0.exe" (
 start "" "%~dp0build\Hordas-0.21.0\Hordas-0.21.0.exe"
 exit /b
)
where godot >nul 2>nul
if not errorlevel 1 (
 start "" godot --path "%~dp0."
 exit /b
)
where godot4 >nul 2>nul
if not errorlevel 1 (
 start "" godot4 --path "%~dp0."
 exit /b
)
if exist "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64_console.exe" (
 start "" "%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64_console.exe" --path "%~dp0."
 exit /b
)
echo Instale o Godot 4.7.2, importe project.godot e aperte F5.
pause
