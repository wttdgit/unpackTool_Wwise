@echo off
setlocal enabledelayedexpansion
for /r %%a in (*.done) do (
    set bnkfile=%%~nxa
    rename %%a !bnkfile:~0,-5!
)