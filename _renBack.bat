@echo off
setlocal enabledelayedexpansion
for /r "wwiseBank" %%a in (*.done) do (
    set bnkfile=%%~nxa
    rename %%a !bnkfile:~0,-5!
)