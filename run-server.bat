@echo off
setlocal
call "%~dp0tools.bat" server %*
set "LAB_EXIT=%errorlevel%"
if not "%LAB_EXIT%"=="0" if not "%LAB_NO_PAUSE%"=="1" pause
exit /b %LAB_EXIT%
