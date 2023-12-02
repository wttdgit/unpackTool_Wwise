@echo off
    setlocal enabledelayedexpansion
    set input_folder=%~dp0SoundBank
    set output_folder=Ogg
    set threadNum=0
    for /f %%t in (Tools\_thread.txt) do (set threadMax=%%t)
    for /l %%i in (1,1,!threadMax!) do (
        for /f %%f in (Tools\_list.txt) do (
            md "Tools\_%%i\Decoding_%%i"
            if not exist "Tools\_%%i\%%~nf_%%i%%~xf" (
                copy "Tools\%%~f" "Tools\_%%i\%%~nf_%%i%%~xf"
            )
        )
    ) >nul 2>nul

:main
    for %%t in (pck bnk wem) do (
        set total_count=0
        set done_count=0
        for /r "%input_folder%" %%a in (*.%%t) do (set /a total_count+=1)
        for /r "%input_folder%" %%a in (*.%%t) do (
            :reCount
            set /a threadNum+=1
            set threadCur=0
            for /f %%a in ('tasklist /fi "imagename eq cmd.exe" /fi "status eq running"') do (set /a threadCur+=1)
            if !threadCur! leq !threadMax! (
                if !threadNum! leq !threadMax! (
                    set suffix=_!threadNum!
                ) else (
                    set "threadNum=1" && set suffix=_!threadNum!
                )
            ) else (
                waitfor /s localhost /si processDone >nul 2>nul && goto reCount
            )
            set relative_path=%%~dpa
            set relative_path=!relative_path:%input_folder%\=!
            call :outpath_%%t %%~na
            md "!output_subfolder!" >nul 2>nul
            tasklist /fi "imagename eq cmd.exe" /v | findstr /i "processAudio!suffix!" >nul 2>nul
            if !errorlevel! equ 0 (
                waitfor /s localhost /si processAudio!suffix! >nul 2>nul
            )
            start /b "" Tools\!suffix!\processAudio!suffix!.bat "%%a" "!output_subfolder!"
            set /a done_count+=1
            cls & title !total_count!-!done_count!
        )
        call :waitExport
    )
:count
    set ogg_count=0
    for /r %output_folder% %%a in (*.ogg) do (set /a ogg_count+=1)
    cls
    echo wem Total: !total_count!
    echo wem Done : !done_count!
    echo ogg Out  : !ogg_count!
    echo Convert Done^^!
:clean
    cd Tools
    call _tempDel.bat 2>nul
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
    set output_subfolder=%output_folder%\!relative_path!
    goto :eof

:waitExport
    for /f "delims=_" %%f in (Tools\_list.txt) do (tasklist /fi "status eq running"|findstr /i "%%~nf") >> waitWhat
    set /p waitWhat=<waitWhat
    del waitWhat 2>nul
    if "!waitWhat!" neq "" (
        waitfor /s localhost /si processDone >nul 2>nul
        goto waitExport
    )
    goto :eof