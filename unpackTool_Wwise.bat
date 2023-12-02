@echo off
    setlocal enabledelayedexpansion
    set input_folder=%~dp0SoundBank
    set output_folder=Ogg
    set thread_index=0
    for /f %%t in (Tools\thread.txt) do (set thread_count=%%t)
    for /l %%i in (1,1,!thread_count!) do (
        copy Tools\ww2ogg.exe Tools\ww2ogg_%%i.exe
        copy Tools\revorb.exe Tools\revorb_%%i.exe
        copy Tools\quickbms.exe Tools\quickbms_%%i.exe
        copy Tools\bnkextr.exe Tools\bnkextr_%%i.exe
        copy Tools\processAudio.bat Tools\processAudio_%%i.bat
    ) >nul 2>nul
:main
    for %%t in (pck bnk wem) do (
        set total_count=0
        set done_count=0
        for /r "%input_folder%" %%a in (*.%%t) do (set /a total_count+=1)
        for /r "%input_folder%" %%a in (*.%%t) do (
            set /a thread_index+=1
            if !thread_count! neq 1 (
				if !thread_index! leq !thread_count! (set suffix=_!thread_index!) else (set thread_index=0 & waitfor /t 1 Signal >nul 2>nul)
			)
            set relative_path=%%~dpa
            set relative_path=!relative_path:%input_folder%\=!
            call :outpath_%%t %%~na
            md "!output_subfolder!" >nul 2>nul
            tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio!suffix!" >nul 2>nul
            if !errorlevel! equ 0 (waitfor /s localhost /si processAudio!suffix!) >nul 2>nul
            start /min "" Tools\processAudio!suffix!.bat "%%a" "!output_subfolder!"
            set /a done_count+=1
            cls & title !thread_index!
            echo %%t Total: !total_count!
            echo %%t Done : !done_count!
            if !thread_index! geq !thread_count! (set thread_index=0 & waitfor /t 1 Signal >nul 2>nul)
        )
        call :waitExport
    )
:count
    set ogg_count=0
    for /r %output_folder% %%a in (*.ogg) do (set /a ogg_count+=1)
    echo ogg Out  : !ogg_count!
    echo Convert Done^^!
:clean
    cd Tools
    call tempDel.bat 2>nul
    pause
    exit

:outpath_pck
    md "%input_folder%\PCK2BNK\!relative_path!" >nul 2>nul
    set output_subfolder=%input_folder%\PCK2BNK\!relative_path!\%~1
	goto :eof
:outpath_bnk
    md "%output_folder%\!relative_path!" >nul 2>nul
    set output_subfolder=%output_folder%\!relative_path!\%~1
	goto :eof
:outpath_wem
    md "Tools\Decoding!suffix!" >nul 2>nul
    set output_subfolder=%output_folder%\!relative_path!
	goto :eof

:waitExport
    tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio" >nul 2>nul
    if !errorlevel! equ 0 (
        timeout 1 >nul
        goto waitExport
    )
	goto :eof