@echo off

rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 --colorBD green --colorUL magenta -e ssh -X hsolomon@lb-bft18
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 --colorBD green --colorUL magenta -e ssh -X hsolomon@arc-dev09
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 -si -sw --colorBD green --colorUL magenta -e ssh hsolomon@arc-serv01
rem rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 --colorBD green --colorUL magenta -e ssh -X hsolomon@arc-serv01

echo rxvt -geometry 80x42 -fn "Lucida Console" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 4096 -si -sw --colorBD green --colorUL magenta -e ssh hsolomon@arc-serv01 %1

