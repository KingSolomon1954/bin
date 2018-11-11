@echo off
C:
chdir \cygwin\bin

C:\cygwin\bin\rxvt.exe -display :0 -tn rxvt-cygwin-native -geometry 80x42 -fn "Lucida Console-12" -title "rxvt" -bg black -fg springgreen3 -cr white -ls -sr -sl 10000 --colorBD green --colorUL magenta -e /bin/bash --login -i
