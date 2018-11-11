@Echo Off

REM File: do_bwa
REM 
REM Script to setup development environment
REM for broadband wireless access product
REM under NT (using cmd.exe).
REM 
REM -------------------------------------------------------

REM This is required by the Makefiles
set WBA_TIP_BASE=e:\bwa

REM These are required by Tornado
set WIND_BASE=%WBA_TIP_BASE%\Tools\Tornado
set WIND_HOST_TYPE=x86-win32

set PATH=%PATH%;e:\opus_make\NT
set PATH=%PATH%;%WIND_BASE%\host\%WIND_HOST_TYPE%\bin
set PATH=%PATH%;%WBA_TIP_BASE%\tools\buildtools\bin
