@echo off
setlocal
set input_file=%~1
set output_folder=%~2
set suffix=%~n0
set suffix=%suffix:processAudio=%
md "Tools\Decoding%suffix%" >nul 2>nul
(
	if "%input_file:~-4%"==".bnk" (Tools\bnkextr%suffix%.exe "%input_file%")
    Tools\quickbms%suffix%.exe -k -q -Y "Tools\wavescan.bms" "%input_file%" "Tools\Decoding%suffix%"
    move "*.WAV" "Tools\Decoding%suffix%"
    for %%b in (Tools\Decoding%suffix%\*.wav) do (
        "Tools\ww2ogg%suffix%.exe" "%%b" --pcb Tools\packed_codebooks_aoTuV_603.bin
        del "%%b"
    )
    for %%c in (Tools\Decoding%suffix%\*.ogg) do (
        "Tools\revorb%suffix%.exe" "%%c"
        move /Y "%%c" "%output_folder%"
    )
) >nul
waitfor /s localhost /si processAudio%suffix% >nul 2>nul
exit