@echo off
rem set CYGWIN=tty
C:
chdir \cygwin\bin

set login=%1
if "%2"=="vcabft02" set useDashX=-Y

rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 --colorBD green --colorUL magenta -e ssh -X hsolomon@arc-dev09
rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 -si -sw --colorBD green --colorUL magenta -e ssh %useDashX% %login%@%2
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 -si -sw --colorBD green --colorUL magenta -e ssh hsolomon@arc-serv01
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 -si -sw --colorBD green --colorUL magenta -e ssh hsolomon@vcabft02
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 --colorBD green --colorUL magenta -e ssh -X hsolomon@arc-serv01

