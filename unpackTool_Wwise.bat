@echo off & setlocal enabledelayedexpansion
set input_folder=%~dp0SoundBank
set output_folder=Ogg
set thread_index=0
set total_count=0
set done_count=0

for /r "%input_folder%" %%a in (*.pck) do (
	md "%input_folder%\PCK2BNK\%%~na" >nul 2>nul
	"Tools\quickbms.exe" "Tools\wwise_pck_extractor.bms" "%%a" "%input_folder%\PCK2BNK\%%~na"
)

for /f %%t in (Tools\thread.txt) do (set thread_count=%%t)
for /l %%i in (1,1,!thread_count!) do (
    copy Tools\ww2ogg.exe Tools\ww2ogg_%%i.exe
    copy Tools\revorb.exe Tools\revorb_%%i.exe
    copy Tools\quickbms.exe Tools\quickbms_%%i.exe
    copy Tools\bnkextr.exe Tools\bnkextr_%%i.exe
    copy Tools\processAudio.bat Tools\processAudio_%%i.bat
) >nul 2>nul

for /r "%input_folder%" %%a in (*.bnk) do (
    set relative_path=%%~dpa
    set relative_path=!relative_path:%input_folder%\=!
    md "%output_folder%\!relative_path!" >nul 2>nul
    set output_subfolder=%output_folder%\!relative_path!\%%~na
    md "!output_subfolder!" >nul 2>nul
    set /a thread_index+=1
    if !thread_index! leq !thread_count! (
        set suffix=_!thread_index!
    ) else (
        set suffix=
    )
    tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio!suffix!.bat" >nul 2>nul
    if !errorlevel! equ 0 (waitfor /s localhost /si processAudio!suffix!) >nul 2>nul
    start /min "" Tools\processAudio!suffix!.bat "%%a" "!output_subfolder!"
    if !thread_index! geq !thread_count! (
        set thread_index=0
        waitfor /t 1 Signal
    ) >nul 2>nul
) >nul

for /r "%input_folder%" %%a in (*.wem) do (set /a total_count+=1)
for /r "%input_folder%" %%a in (*.wem) do (
    set relative_path=%%~dpa
    set relative_path=!relative_path:%input_folder%\=!
    set output_subfolder=%output_folder%\!relative_path!	
    md "!output_subfolder!" >nul 2>nul
    set /a thread_index+=1
    if !thread_index! leq !thread_count! (
        set suffix=_!thread_index!
    ) else (
        set suffix=
    )
    tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio!suffix!.bat" >nul 2>nul
    if !errorlevel! equ 0 (waitfor /s localhost /si processAudio!suffix!) >nul 2>nul
    start /min "" Tools\processAudio!suffix!.bat "%%a" "!output_subfolder!"
    set /a done_count+=1
    cls
    echo Total: !total_count!
    echo Done : !done_count!
    if !thread_index! geq !thread_count! (
        set thread_index=0
        waitfor /t 1 Signal >nul 2>nul
    )
)

echo Convert Done^^!
:tempDel
tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio" >nul 2>nul
if !errorlevel! equ 0 (
    timeout 1 >nul
    goto tempDel
)
(for /l %%i in (1,1,!thread_count!) do (rd /s /q Tools\Decoding_%%i)
del /q Tools\*_*.exe
del /q Tools\*_*.bat) >nul 2>nul
exit