@echo off
setlocal
rem Only bootstrap Python here. All project operations live in scripts/tools.py.
rem This bootstrap uses Windows curl, certutil and tar; it never changes PATH.
if defined NETCODE_PYTHON goto custom_python
set "LAB_PYTHON="
if exist "%~dp0.venv\Scripts\python.exe" call :try_python "%~dp0.venv\Scripts\python.exe"
if defined LAB_PYTHON goto run
where.exe py.exe >nul 2>&1
if errorlevel 1 goto search_python
py -3 -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
if not errorlevel 1 goto python_launcher
:search_python
for /f "delims=" %%P in ('where.exe python.exe 2^>nul ^| findstr.exe /v /i WindowsApps') do (
    call :try_python "%%P"
    if defined LAB_PYTHON goto run
)
set "LAB_PYTHON_DIR=%~dp0.tools\python-3.14.7"
set "LAB_PYTHON=%LAB_PYTHON_DIR%\python.exe"
if exist "%LAB_PYTHON%" goto run
set "LAB_ARCHIVE=%~dp0.tools\downloads\python-3.14.7-embed-amd64.zip"
if not exist "%~dp0.tools\downloads" mkdir "%~dp0.tools\downloads"
if errorlevel 1 exit /b 1
echo Bootstrapping portable Python 3.14.7...
if exist "%LAB_ARCHIVE%" goto checksum
curl.exe --fail --location --retry 3 --output "%LAB_ARCHIVE%" "https://www.python.org/ftp/python/3.14.7/python-3.14.7-embed-amd64.zip"
if errorlevel 1 exit /b 1
:checksum
certutil.exe -hashfile "%LAB_ARCHIVE%" SHA256 | findstr.exe /i /x "d297e5ff019966817ad8502465176139f2d3d840fa4ed84b13bed399a6ab1f15" >nul
if errorlevel 1 goto bad_checksum
if not exist "%LAB_PYTHON_DIR%" mkdir "%LAB_PYTHON_DIR%"
tar.exe -xf "%LAB_ARCHIVE%" -C "%LAB_PYTHON_DIR%"
if errorlevel 1 exit /b 1
goto run
:custom_python
set "LAB_PYTHON=%NETCODE_PYTHON%"
:run
"%LAB_PYTHON%" -X utf8 "%~dp0scripts\tools.py" %*
exit /b %errorlevel%
:python_launcher
py -3 -X utf8 "%~dp0scripts\tools.py" %*
exit /b %errorlevel%
:try_python
"%~1" -c "import sys; sys.exit(sys.version_info < (3, 11))" >nul 2>&1
if not errorlevel 1 set "LAB_PYTHON=%~1"
exit /b 0
:bad_checksum
echo ERROR: Python archive SHA256 mismatch. Move the archive aside and retry.
exit /b 1
