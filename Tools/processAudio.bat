@echo off
title %~n0
setlocal enabledelayedexpansion
set suffix=%~n0
set suffix=!suffix:processAudio=!
(
    if "%~x1"==".pck" (Tools\quickbms!suffix!.exe -k -q -Y "Tools\wwise_pck_extractor.bms" "%~1" "%~2")
    if "%~x1"==".bnk" (Tools\bnkextr!suffix!.exe "%~1" && rename "%~1" "bnk_%~n1.done")
    if "%~x1"==".wem" (
        Tools\quickbms!suffix!.exe -k -q -Y "Tools\wavescan.bms" "%~1" "Tools\Decoding!suffix!"
        move "*.WAV" "Tools\Decoding!suffix!"
        for %%b in (Tools\Decoding!suffix!\*.wav) do (
            "Tools\ww2ogg!suffix!.exe" "%%b" --pcb Tools\packed_codebooks_aoTuV_603.bin
            del "%%b"
        )
        for %%c in (Tools\Decoding!suffix!\*.ogg) do (
            "Tools\revorb!suffix!.exe" "%%c"
            set oggName=%%~nc
            if "!oggName:~-2!"=="_1" rename "%%c" "!oggName:~0,-2!.ogg"
            move /Y "%%c" "%~2\"
        )
    )
) > nul
waitfor /s localhost /si processAudio!suffix! >nul 2>nul
exit