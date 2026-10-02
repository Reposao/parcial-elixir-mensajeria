@echo off
chcp 65001 > nul
cd /d "%~dp0"
elixir -r datos.exs -r util2.exs -r validacion.exs -r liquidacion.exs -r investigacion.exs -r reportes.exs principal.exs
pause
