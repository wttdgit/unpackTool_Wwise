@echo off & setlocal enabledelayedexpansion
set input_folder=%~dp0SoundBank
set output_folder=Ogg
set thread_index=0
rem 线程数修改Tools\thread.txt、建议3以内
for /f %%t in (Tools\thread.txt) do (set thread_count=%%t)
rem PCK转BNK
for /r "%input_folder%" %%a in (*.pck) do (
	if not exist "%input_folder%\PCK2BNK\%%~na" md "%input_folder%\PCK2BNK\%%~na"
	"Tools\quickbms.exe" "Tools\wwise_pck_extractor.bms" "%%a" "%input_folder%\PCK2BNK\%%~na"
)
rem 复制原始的exe按照线程数添加后缀
for /l %%i in (1,1,!thread_count!) do (
    copy Tools\ww2ogg.exe Tools\ww2ogg_%%i.exe >nul 2>&1
    copy Tools\revorb.exe Tools\revorb_%%i.exe >nul 2>&1
    copy Tools\quickbms.exe Tools\quickbms_%%i.exe >nul 2>&1
    copy Tools\bnkextr.exe Tools\bnkextr_%%i.exe >nul 2>&1
    copy Tools\processAudio.bat Tools\processAudio_%%i.bat >nul 2>&1
)
rem 计算输入文件夹中的wem文件的总数
set total_count=0
for /r "%input_folder%" %%a in (*.wem) do (set /a total_count=total_count+1)
rem 初始化已处理文件的计数和已导出文件的计数
set done_count=0
for /r "%input_folder%" %%a in (*.wem *.bnk) do (
    set output_count=0
    set relative_path=%%~dpa
    set relative_path=!relative_path:%input_folder%\=!
    md "%output_folder%\!relative_path!" >nul 2>&1
    if "%%~xa"==".bnk" (
        md "%output_folder%\!relative_path!\%%~na" >nul 2>&1
        set output_subfolder=%output_folder%\!relative_path!\%%~na
    ) else (
        set output_subfolder=%output_folder%\!relative_path!
    )
    set /a thread_index=thread_index+1
    if !thread_index! leq !thread_count! (
        set suffix=_!thread_index!
    ) else (
        set suffix=
    )
    rem 检查当前的processAudio!suffix!.bat是否正在运行，如果是，就等待它结束
    tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio!suffix!.bat" >nul 2>&1
    if !errorlevel! equ 0 (waitfor /s localhost /si processAudio!suffix! >nul 2>&1)
    rem 启动子函数processAudio!suffix!.bat，并传递参数"%%a" "!output_subfolder!"给子函数
    start /min "!thread_index!" Tools\processAudio!suffix!.bat "%%a" "!output_subfolder!"
    rem 更新已处理WEM的计数
    set /a done_count=done_count+1
    rem 更新成功导出OGG的计数
    for /r "%output_folder%" %%o in (*.ogg) do (set /a output_count=output_count+1)
    rem 标题栏显示当前的进度
    title Total!total_count!-Done!done_count!-Out!output_count!
    if !thread_index! geq !thread_count! (
        set thread_index=0
        waitfor /t 1 Signal >nul 2>&1
    )
)
echo Convert Done^^!
:tempDel
tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio" >nul 2>&1
if !errorlevel! equ 0 (
    timeout 1 >nul 2>&1
    goto tempDel
)
for /l %%i in (1,1,!thread_count!) do (rd /s /q Tools\Decoding_%%i) >nul 2>&1
del /q Tools\*_*.exe >nul 2>&1
del /q Tools\*_*.bat >nul 2>&1
exit
