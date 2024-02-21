@echo OFF
setlocal EnableDelayedExpansion
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a")
set SCHEDULE_NAME="gbfr_backup"
set SCHEDULER_TIME_MINUTE=10
set "BATCH_PATH=%~f0"
set "APP_PROCESS_NAME=granblue_fantasy_relink"
set "BACKUP_PRE_NAME=SaveGames"
set "BACKUP_TARGET_PATH=%LOCALAPPDATA%\GBFR\Saved\SaveGames\"
set "BACKUP_DEST_PATH=%BACKUP_TARGET_PATH%"
set DELETE_DAYS=-1

call :CheckAppRunning
IF "%errorlevel%" equ "0" (
	echo "Not Running %APP_PROCESS_NAME%"
	pause
	exit /b
)

IF "%1" == "1" (
	call :CreateZip
	exit /b
)

call :main
pause
exit /b

:main
call :CheckPermissions
IF "%errorlevel%" neq "0" (
	exit /b
)
call :SelectCommand
IF "%inputType%" == "1" (
	call :IsExistSchedule
	IF "%errorlevel%" == "1" (
		call :CreateSchedule
	) ELSE (
		echo "Already Exist Schedule"
	)
)

IF "%inputType%" == "2" (
	call :DeleteSchedule
)

IF "%inputType%" == "3" (
	call :CreateZip
)
exit /b

:CreateZip
setlocal
set curDateTime=%date:~2,2%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
echo Zipping...
powershell -NonInteractive -command "try { Compress-Archive -Path '%BACKUP_TARGET_PATH%' -DestinationPath '%BACKUP_DEST_PATH%%BACKUP_PRE_NAME%_%curDateTime%.zip' } catch { }" 2>NUL >NUL
call :ShowText Zipping
IF %errorlevel% == 0 (
	call :DeleteOldFile
	call :ShowText "Delete Files of %DELETE_DAYS% Days"
)
endlocal
exit /b

:DeleteOldFile
setlocal
echo "%BACKUP_DEST_PATH%"
forfiles /p %BACKUP_DEST_PATH% /s /m %BACKUP_PRE_NAME%_*.zip /D %DELETE_DAYS% /c "cmd /c del @path" 2>NUL >NUL
endlocal
exit /b

:CreateSchedule
setlocal
schtasks /create /tn %SCHEDULE_NAME% /ru "SYSTEM" /tr "cmd.exe /C %BATCH_PATH% 1" /sc minute /mo %SCHEDULER_TIME_MINUTE% 2>NUL >NUL
call :ShowText "Create Schedule"
endlocal
exit /b

:DeleteSchedule
setlocal
schtasks /f /delete /tn %SCHEDULE_NAME% 2>NUL >NUL
call :ShowText "Delete Schedule"
endlocal
exit /b

:IsExistSchedule
setlocal
schtasks /query /tn %SCHEDULE_NAME% 2>NUL >NUL
endlocal
exit /b %errorlevel%

:SelectCommand
echo ====================================================================================================
echo Select Number
echo 1 ] Create Schedule
echo 2 ] Delete Schedule
echo 3 ] Force Create Backup zip File
echo q ] Exit
echo ====================================================================================================
set /p inputType="Select Number : "

IF "%inputType%" == "q" ( exit )
IF "%inputType%" == "Q" ( exit )

echo %inputType%|findstr /r "[^0-9|q|Q]" && (
	echo Invalid Input Data
	pause
	cls
    goto :SelectCommand
)

IF %inputType% gtr 3 (
	cls
	goto :SelectCommand
)

IF %inputType% lss 1 (
	cls
	goto :SelectCommand
)

exit /b

:ShowText
	IF %errorlevel% == 0 (
		echo. | set /p dummyText=%~1
			call :ColorText 00 " [" & call :ColorText 02 "SUCCEED" & call :ColorText 00 "]"
		echo.
	) ELSE (
		echo. | set /p dummyText=%~1
			call :ColorText 00 " [" & call :ColorText 04 "FAILED" & call :ColorText 00 "]"
		echo.
	)
exit /b

:CheckPermissions
    echo Administrative permissions required. Detecting permissions...

    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo Success: Administrative permissions confirmed.
    ) else (
        echo Failure: Current permissions inadequate.
    )
exit /b %errorLevel%

:CheckAppRunning
for /f "delims=" %%a in ('powershell -NonInteractive -command "Get-Process|?{$_.Name -eq '%APP_PROCESS_NAME%'}"') do Set "getProcess=%%a"
IF "%getProcess%" equ "" (
	set "isExistApp=0"
) ELSE (
	set "isExistApp=1"
)
exit /b %isExistApp%

:ColorText
<nul set /p "=%DEL%" > "%~2"
findstr /v /a:%1 /R "+" "%~2" nul
del "%~2" > nul
goto :eof
