@echo off
setlocal
rem A shared config is optional when the tools are already on PATH.
if defined NETCODE_ENV (
    if not exist "%NETCODE_ENV%" (
        echo ERROR: NETCODE_ENV does not point to an existing configuration file.
        exit /b 2
    )
    call "%NETCODE_ENV%"
) else (
    if exist "%~dp0..\environment.local.bat" call "%~dp0..\environment.local.bat"
)
if defined NETCODE_PYTHON goto custom_python
set "LAB_PYTHON="
where.exe py.exe >nul 2>&1
if errorlevel 1 goto search_python
py -3 -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
if not errorlevel 1 goto python_launcher
:search_python
for /f "delims=" %%P in ('where.exe python.exe 2^>nul ^| findstr.exe /v /i WindowsApps') do (
    call :try_python "%%P"
    if defined LAB_PYTHON goto run
)
echo ERROR: Python 3.11+ was not found. No automatic installation is performed.
echo Install Python once in your preferred directory. See docs\ENVIRONMENT.md.
echo Set NETCODE_PYTHON or configure the shared environment.local.bat file.
exit /b 2
:custom_python
set "LAB_PYTHON=%NETCODE_PYTHON%"
call :try_python "%LAB_PYTHON%"
if errorlevel 1 (
    echo ERROR: NETCODE_PYTHON must point to a working Python 3.11+ executable.
    exit /b 2
)
:run
"%LAB_PYTHON%" -X utf8 "%~dp0scripts\tools.py" %*
exit /b %errorlevel%
:python_launcher
py -3 -X utf8 "%~dp0scripts\tools.py" %*
exit /b %errorlevel%
:try_python
"%~1" -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
if errorlevel 1 exit /b 1
set "LAB_PYTHON=%~1"
exit /b 0
