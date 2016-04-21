cd c:\
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
git clean -dfx
echo %USERPROFILE%
echo START TO CLEAN ALL PREVIOUS DISTRIBUTION
SET /A errno=0
mkdir mediaengine\bin\Win32\Release
copy vendor\wbxtrace\libs\windows\wbxtrace.dll mediaengine\bin\Win32\Release\

echo START TO BUILD SDK
cd build\windows
git checkout build_2013.py
sed -i "s/msbuild /msbuild \/m:3 /" build_2013.py
python build_2013.py release
if %fast_mode%==no (python build_2013.py debug)
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
git checkout build_2013.py

sed -i 's/^#cmd = \"7z/cmd = \"7z/'   package2013.py
sed -i 's/^cmd = \"zip/#cmd = \"zip/' package2013.py
python package2013.py pdb
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

::pdb packages
7z a win32-release-pdbs.zip  ./MediaSDK_Demo_Windows/pdbs/Win32/Release/*

git checkout package2013.py
python package4train.py

EXIT /B %errno%

::::::::::::::::::::::::::::::::::::::

call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\vsvars32.bat"
cd c:\

SET /A errno=0

echo START TO BUILD REF-APP
::Build windows ref-app for TA
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\ta\ref-app\windows
nuget.exe restore MediaSessionTest.sln
msbuild MediaSessionTest.sln /t:Clean
msbuild MediaSessionTest.sln /p:Configuration=Release
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
EXIT /B %errno%

:::::::::::::::::::::::::::
cd c:\
SET /A errno=0
set Configuration=release

echo START TO BUILD MANUAL TEST APP
::Build windows ref-app for manual testing
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows
python build_ref_app.py
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

echo START TO BUILD UT TEST APP
sed -i "s/msbuild /msbuild \/m:3 /" build_ut2013.py
python build_ut2013.py
IF %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
git checkout build_ut2013.py

::Archive the artifacts
echo START TO PACKAGE ALL
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows
rm -fr ../../mediaengine/libs/Win32/Debug/*.exp
rm -fr ../../mediaengine/libs/Win32/Release/*.exp

7z a win-release.zip ../../distribution/windows/%Configuration%/*.dll ../../distribution/windows/Win32/Release/*.dll ../../mediaengine/libs

7z a wme4netTest.zip  ../../distribution/windows/%Configuration%/*.exe ../../distribution/windows/Win32/Release/*.exe

7z a win-ut-ta-app.zip ../../mediaengine/bin/Win32/Release/*.exe
::rm -f ../../mediaengine/bin/Win32/Release/*.dll
::7z a win-ut-ta-app.zip ../../mediaengine/bin/Win32/Release/*.exe
::for /f "usebackq" %%i in (`"git rev-parse origin/master"`) do @set wme_rev=%%i
cd ..\..\
rm -rf INFO-Win-Package-*
touch INFO-Win-Package-%parent_build_number%-j%BUILD_NUMBER%-%git_commit_revision%

EXIT /B %errno%