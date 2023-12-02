@echo off
setlocal enabledelayedexpansion
title %~n0
set suffix=%~n0
set suffix=!suffix:processAudio=!
(
    if "%~x1"==".pck" (Tools\!suffix!\quickbms!suffix!.exe -k -q -Y "Tools\!suffix!\wwise_pck_extractor!suffix!.bms" "%~1" "%~2")
    if "%~x1"==".bnk" (Tools\!suffix!\bnkextr!suffix!.exe "%~1" && rename "%~1" "%~x1%~n1")
    if "%~x1"==".wem" (
        Tools\!suffix!\quickbms!suffix!.exe -k -q -Y "Tools\!suffix!\wavescan!suffix!.bms" "%~1" "Tools\!suffix!\Decoding!suffix!"
        move "*.WAV" "Tools\!suffix!\Decoding!suffix!"
        for %%b in (Tools\!suffix!\Decoding!suffix!\*.wav) do (
            "Tools\!suffix!\ww2ogg!suffix!.exe" "%%b" --pcb Tools\!suffix!\packed_codebooks_aoTuV_603!suffix!.bin
            del "%%b"
        )
        for %%c in (Tools\!suffix!\Decoding!suffix!\*.ogg) do (
            "Tools\!suffix!\revorb!suffix!.exe" "%%c"
            set oggName=%%~nc
            if "!oggName:~-2!"=="_1" rename "%%c" "!oggName:~0,-2!.ogg"
            if not exist "%~2\%%c" (move /Y "%%c" "%~2\")
        )
    )
) >nul 2>nul
waitfor /s localhost /si processAudio!suffix! >nul 2>nul
waitfor /s localhost /si processDone >nul 2>nul
endlocal
exit