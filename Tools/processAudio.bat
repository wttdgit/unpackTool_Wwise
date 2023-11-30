@echo off
setlocal enabledelayedexpansion
set input_file=%1
set output_folder=%2
rem 获取当前线程号
set suffix=%~n0
set suffix=%suffix:processAudio=%
md "Tools\Decoding!suffix!"
Tools\quickbms!suffix!.exe -k -q -Y "Tools\wavescan.bms" "%input_file%" "Tools\Decoding!suffix!"
Tools\bnkextr!suffix!.exe "%input_file%" /nodir
move "*.WAV" "Tools\Decoding!suffix!"
for %%b in (Tools\Decoding!suffix!\*.wav) do (
    "Tools\ww2ogg!suffix!.exe" "%%b" --pcb Tools\packed_codebooks_aoTuV_603.bin
    del "%%b"
)
for %%c in (Tools\Decoding!suffix!\*.ogg) do (
    "Tools\revorb!suffix!.exe" "%%c"
    move "%%c" "%output_folder%"
)
rem 发送信号给主函数-当前线程已结束
waitfor /s localhost /si processAudio!suffix! >nul 2>&1
exit
