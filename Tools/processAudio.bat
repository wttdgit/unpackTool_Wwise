@echo off
title %~n0
setlocal
set suffix=%~n0
set suffix=%suffix:processAudio=%

(
    if "%~x1"==".pck" (Tools\quickbms%suffix%.exe -k -q -Y "Tools\wwise_pck_extractor.bms" "%~1" "%~2")
    if "%~x1"==".bnk" (Tools\bnkextr%suffix%.exe "%~1" /nodir)
    if "%~x1"==".wem" (
	    md "Tools\Decoding%suffix%" >nul 2>nul
		Tools\quickbms%suffix%.exe -k -q -Y "Tools\wavescan.bms" "%~1" "Tools\Decoding%suffix%"
		move "*.WAV" "Tools\Decoding%suffix%"
		for %%b in (Tools\Decoding%suffix%\*.wav) do (
			"Tools\ww2ogg%suffix%.exe" "%%b" --pcb Tools\packed_codebooks_aoTuV_603.bin
			del "%%b"
		)
		for %%c in (Tools\Decoding%suffix%\*.ogg) do (
			"Tools\revorb%suffix%.exe" "%%c"
			move /Y "%%c" "%~2"
		)
	)
) > nul
waitfor /s localhost /si processAudio%suffix% >nul 2>nul
exit
