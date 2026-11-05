# Runs the tests with a hard time limit and direct file output, so no pipe holds the text back.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools\correr_pruebas.ps1 [-Limite 270]
param([int]$Limite = 270)

$g = "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
$proyecto = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $proyecto 'build\pruebas'
New-Item -ItemType Directory -Force $dir | Out-Null
$out = Join-Path $dir 'salida.txt'
$err = Join-Path $dir 'errores.txt'

$p = Start-Process -FilePath $g -ArgumentList '--headless', '--path', "`"$proyecto`"", '--script', 'res://tests/run_tests.gd' `
	-RedirectStandardOutput $out -RedirectStandardError $err -NoNewWindow -PassThru
$null = $p.Handle
$colgado = -not $p.WaitForExit($Limite * 1000)
if ($colgado) {
	taskkill /PID $p.Id /T /F | Out-Null
	Write-Output "TIME LIMIT of $Limite s reached: process stopped."
}
Start-Sleep -Milliseconds 500

Get-Content $out -Encoding UTF8 | Where-Object { $_ -match '^(ok|\d+ pruebas|\s+paso de)' }
Write-Output '--- FALLOS ---'
Get-Content $err -Encoding UTF8 | Where-Object { $_ -match '^FALLO|tiempo l.mite' } | ForEach-Object { if ($_.Length -gt 300) { $_.Substring(0, 300) + '...' } else { $_ } }
Write-Output '--- COMPILACION ---'
Get-Content $err -Encoding UTF8 | Where-Object { $_ -match 'Parse Error|Compile Error' } | Select-Object -Unique -First 12

# The summary line only prints if the runner finished, so its absence always counts as failure.
$resumen = Get-Content $out -Encoding UTF8 | Where-Object { $_ -match '^\d+ pruebas, 0 fallos' }
if ($colgado -or -not $resumen -or $p.ExitCode -ne 0) {
	Write-Output "RESULT: FAILED (exit code $($p.ExitCode))"
	exit 1
}
Write-Output 'RESULT: OK'
