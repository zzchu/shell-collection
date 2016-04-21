@echo off
cd c:\Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
git clean -dfx

cd c:\
mkdir \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\mediaengine\bin\Win32\Release

cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\mediaengine\bin\Win32\Release
if %bld_win32_url% == None (set bld_win32_url=%UPSTREAM_URL%)
SET UPSTREAM_BASE=%bld_win32_url%/artifact/%repo_loc%/%wme_loc%/build/windows
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 %UPSTREAM_BASE%/win-release.zip
7z x win-release.zip
DEL /F /Q /S win-release.zip
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 %UPSTREAM_BASE%/win-ut-ta-app.zip
7z x win-ut-ta-app.zip
DEL /F /Q /S win-ut-ta-app.zip
EXIT /B 0



::::::::::::::::

set HOME=%USERPROFILE%
echo START TO BUILD UT APP
echo "[*]Build Media SDK Unit Test--Windows"
cd c:\
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows

echo START TO RUN UT
echo "[*]Run Media SDK Unit Test--Windows"
SET /A errno=0
echo "[*]Default value BuildAll is chosen; Build and Run All UT modules"
python run_ut.py

IF %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

cd c:\

cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows
7z a win_release_ut_report.zip  ..\..\mediaengine\bin\Win32\Release\*.xml
7z a win_release_ut_logs.zip  %temp%\*.wbt

cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
rm -rf INFO-UT-WIN*

::for /f "usebackq" %%i in (`"git rev-parse origin/master"`) do @set rev=%%i
::SET wme_rev=%git_commit_revision:~0,7%
touch INFO-UT-WIN-p%parent_build_number%-s%BUILD_NUMBER%-%git_commit_revision%
EXIT /B 0

IF %errno% GEQ 1 EXIT /B 1