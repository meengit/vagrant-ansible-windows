@echo off

set CYGWIN=C:\cygwin64

REM You can switch this to work with bash with %CYGWIN%binzsh.exe
set SH=%CYGWIN%\bin\bash.exe

"%SH%" -c "/usr/local/bin/ansible %*"
