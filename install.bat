@ECHO OFF

set OLDDIR=%CD%

ECHO Creating directory c:\users\sdi3000...
ECHO.  
MKDIR c:\users\sdi3000

IF NOT EXIST c:\users\sdi3000 goto NeedAdmin

cd c:\users\sdi3000

IF "%~1"=="" GOTO SkipArg1
IF EXIST %~1 ECHO %~1 Already exists, remove it first, skipping over... && GOTO SkipArg1
cmd /C git clone https://github.com/dopplerimager/%~1
ECHO.
IF EXIST %~1 ECHO Successfully to cloned %~1
IF NOT EXIST %~1 ECHO Failed to clone %~1
ECHO.
:SkipArg1

IF "%~2"=="" GOTO SkipArg2
IF EXIST %~2 ECHO %~2 Already exists, remove it first, skipping over... && GOTO SkipArg2
cmd /C git clone https://github.com/dopplerimager/%~2
ECHO.
IF EXIST %~2 ECHO Successfully to cloned %~2
IF NOT EXIST %~2 ECHO Failed to clone %~2
ECHO.
:SkipArg2

IF "%~3"=="" GOTO SkipArg3
IF EXIST %~3 ECHO %~3 Already exists, remove it first, skipping over... && GOTO SkipArg3
cmd /C git clone https://github.com/dopplerimager/%~3
ECHO.
IF EXIST %~3 ECHO Successfully to cloned %~3
IF NOT EXIST %~3 ECHO Failed to clone %~3
ECHO.
:SkipArg3

MKDIR data
MKDIR log
MKDIR settings
MKDIR screencapture
MKDIR phasemaps

chdir /d %OLDDIR% 

ECHO Finished installing selected components. 
ECHO --------------------------------------------------------------------
ECHO  Remember to update:
ECHO      Windows path variable to point to c:\users\sdi3000\sdi\bin\
ECHO      IDL path, IDL startup file, working directory
ECHO      Main settings file, misc/paths and logging/path
ECHO  Remember to:
ECHO      Run pskill at least once to get rid of license agreement
ECHO      First time psftp is run, you will need to confirm stuff 
ECHO --------------------------------------------------------------------
ECHO Hit any key to exit...
PAUSE
GOTO :eof

:NeedAdmin
ECHO Unable to create c:\users\sdi3000, you might need to run as Administrator
ECHO Hit any key to exit...
PAUSE
