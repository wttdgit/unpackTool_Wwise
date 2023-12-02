@echo off
setlocal enabledelayedexpansion
for /r %%a in (.bnk*) do (
    set bnkfile=%%~nxa
    rename %%a !bnkfile:~4!!bnkfile:~0,4!
    rd /s /q !bnkfile:~4!
)