@echo off

setlocal EnableDelayedExpansion
setlocal EnableExtensions

:: ========  INITIALIZE ENVIROMENT  =========

:: init varialbes
set $version=1.2.0
set $release_date=04.03.2020
set $src_dir=T:\Utility\eshell
set $caseID_file=X:\tempFileCaseid
set $error_note=
set $error=
set $diskpart_cmd=%temp%\diskpart_cmd.txt
set $disk_letter=A
set $log_file=x:\debug.log
set $skip_blancco=False
set $tmp=FALSE
set zip=x:\7zip\7zG.exe
set blanccopack=T:\Utility\Blancco_LUN\Blancco_single_%PROCESSOR_ARCHITECTURE%.7z


call :func_init

:header
call :func_header
if DEFINED $error echo %$error%

if EXIST X:\tempFileCaseid (
    for /f "Delims=" %%A in (X:\tempFileCaseid) do (
        set $caseID=%%A
    )
) else (
    :: Entering the caseID
    set /p $caseID=Enter the caseID  || set $caseID=NONE
)

if %$caseID%==NONE set $tmp=TRUE
if /i %$caseID:~-2% NEQ WR set $tmp=TRUE

if %$tmp%==TRUE (
	set $error=Wrong caseID, try again
	set $tmp=FALSE
	goto header
)
echo TEST

echo.
echo.
set /p $skip_blancco=Skip Blancco? [y]es/[N]o || set $skip_blancco=N

if /i %$skip_blancco%==T set no_blancco=TRUE

echo Skip Blancco: %$skip_blancco% >> %$log_file%
echo caseID: %$caseID% >> %$log_file%

if DEFINED no-blancco (
	echo %~dp1>x:\path.txt
	echo Was defined no-blancco >> %$log_file%
	goto omit_blancco
)

:: erasing disks
t:\tools\blancco\check_blancco -i %$caseID% > NUL 2>&1
if %ERRORLEVEL% equ 0 (
	echo Status blancco: SUCCESSFULL >> %$log_file%
	goto omit_blancco
)

cls
echo. 
echo            ____  __                             
echo           / __ )/ /___ _____  ______________  _ 
echo          / __  / / __ `/ __ \/ ___/ ___/ __ \(_)
echo         / /_/ / / /_/ / / / / /__/ /__/ /_/ /   
echo        /_____/_/\__,_/_/ /_/\___/\___/\____(_)  
echo.                                                 
echo.
echo. 
echo                         _                __  __       
echo   ___  _________ ______(_)___  ____ _   / /_/ /_  ___ 
echo  / _ \/ ___/ __ `/ ___/ / __ \/ __ `/  / __/ __ \/ _ \
echo /  __/ /  / /_/ (__  ) / / / / /_/ /  / /_/ / / /  __/
echo \___/_/   \__,_/____/_/_/ /_/\__, /   \__/_/ /_/\___/ 
echo                             /____/                    
echo                   ___      __       
echo              ____/ (_)____/ /_______
echo             / __  / / ___/ //_/ ___/
echo            / /_/ / (__  ) ,^< (__  ) 
echo            \__,_/_/____/_/^|_/____/  
echo.                          								
echo.
echo.
echo.
echo.

:blanccing
:: start Blancco
if exist x:\blancco rd /q /s x:\blancco > nul
echo Start blancco erase process >> %$log_file%
%zip% x %blanccopack% -ox:\blancco\
start /w x:\Blancco\start.cmd

t:\tools\blancco\check_blancco -i %$caseID% > NUL 2>&1
if %ERRORLEVEL% equ 8 (
	echo Status blancco: FAIL >> %$log_file%
	set $notice=Was a problem with Blancco...
	goto error
)

:omit_blancco



if exist %$diskpart_cmd% del %$diskpart_cmd%


:: creating script for diskpart
echo select disk 0 >> %$diskpart_cmd%
echo clean >> %$diskpart_cmd%
echo convert gpt >> %$diskpart_cmd%
echo create par efi size=1024 >> %$diskpart_cmd%
echo format fs=FAT32 label=UefiSHELL quick >> %$diskpart_cmd%
echo assign letter=%$disk_letter% >> %$diskpart_cmd%
echo create partition primary >> %$diskpart_cmd%
echo select partition 2 >> %$diskpart_cmd%
echo shrink desired = 9000 >> %$diskpart_cmd%
echo create partition primary >> %$diskpart_cmd%
echo format fs=NTFS label=WINDRIVER quick >> %$diskpart_cmd%


diskpart /s %$diskpart_cmd% >nul


:: copying the stuff
mkdir %$disk_letter%:\EFI\BOOT
robocopy %$src_dir%  %$disk_letter%:\EFI\BOOT *.efi

if %ERRORLEVEL% EQU 1 goto ok

:error
cls
echo *********************************************************
echo *                                                       *
echo *                       ERROR :-(                       *
echo *                 Something goes wrong...               *
echo *                                                       *
echo *********************************************************


goto end

:ok
cls
echo *********************************************************
echo *                                                       *
echo *            EFI Shell was proper installed             *
echo *                                                       *
echo *********************************************************

:: ***********************************************************************
::                                 FUNCTIONS
:: ***********************************************************************

:func_init
if exist %$log_file% del %$log_file%
echo START LOGGING > %$log_file%
exit /b

:func_header
:: dispaly header
cls
echo *********************************************************
echo *                                                       *
echo *                  EFI Shell Installer                  *
echo *                                                       *
echo * vresion: %$version%                             %$release_date% *
echo *********************************************************
echo.
exit /b



:end
pause
wpeutil reboot