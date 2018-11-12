REM Recursively copy files to the "P" drive for backup.
REM Copies missing files and files with newer dates.

time/t
xcopy c:\howie \\vianas\Homedir-ST\hsolomon /E/Y/I/R/D/EXCLUDE:c:\howie\bin\backup_home_dir_excludes
time/t
