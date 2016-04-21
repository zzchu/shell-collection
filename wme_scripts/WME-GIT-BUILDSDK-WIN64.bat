set Configuration=release
set Platform=x64

cd c:\
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
git clean -dfx
echo %USERPROFILE%
echo START TO CLEAN ALL PREVIOUS DISTRIBUTION
SET /A errno=0
md mediaengine\bin\%Platform%\%Configuration%
copy vendor\wbxtrace\libs\windows\wbxtrace64.dll mediaengine\bin\%Platform%\%Configuration%

echo START TO BUILD SDK
cd build\windows
git checkout build_2013.py
sed -i "s/msbuild /msbuild \/m:3 /" build_2013.py

python build_2013.py %Platform% %Configuration%

if %fast_mode%==no (python build_2013.py %Platform% debug)
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
git checkout build_2013.py

sed -i 's/^#cmd = \"7z/cmd = \"7z/'   package2013.py
sed -i 's/^cmd = \"zip/#cmd = \"zip/' package2013.py
python package2013.py pdb %Platform%
ren MediaSDK_Demo_Windows.zip MediaSDK_Demo_Windows64.zip
echo ERRORLEVEL is %ERRORLEVEL%
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

::pdb packages
7z a win64-release-pdbs.zip  ./MediaSDK_Demo_Windows/pdbs/%Platform%/%Configuration%/*

git checkout package2013.py
python package4train.py %Platform% %Configuration%

echo errno is %errno%
EXIT /B %errno%

::::::::::::::::::::::::::::::::

call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\vsvars32.bat"

SET /A errno=0
set Configuration=release
set Platform=x64

echo START TO BUILD REF-APP
::Build windows ref-app for TA
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\ta\ref-app\windows
::nuget.exe restore MediaSessionTest.sln

msbuild MediaSessionTest.sln /t:Clean
msbuild MediaSessionTest.sln /p:Platform=%Platform% /p:Configuration=%Configuration%
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
EXIT /B %errno%

::::::::::::::::::::::::::::::
cd c:\
SET /A errno=0
set Configuration=release
set Platform=x64

echo errno is %errno%
echo START TO BUILD MANUAL TEST APP
::Build windows ref-app for manual testing
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows
python build_ref_app.py  %Platform% %Configuration%
echo %ERRORLEVEL%
echo errno is %errno%
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%


echo START TO BUILD UT TEST APP
sed -i "s/msbuild /msbuild \/m:3 /" build_ut2013.py
python build_ut2013.py %Platform% %Configuration%

echo ERRORLEVEL is %ERRORLEVEL%
IF %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
git checkout build_ut2013.py


::Archive the artifacts
echo START TO PACKAGE ALL
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\windows
rm -fr ../../mediaengine/libs/%Platform%/Debug/*.exp
rm -fr ../../mediaengine/libs/%Platform%/Release/*.exp

7z a win-release.zip ../../distribution/windows/%Platform%/%Configuration%/*.dll  ../../mediaengine/libs/%Platform%/%Configuration%/*

7z a win-wme4netTest.zip  ../../distribution/windows/%Platform%/%Configuration%/*.exe ../../distribution/windows/%Platform%/%Configuration%/*.exe

7z a win-ut-ta-app.zip ../../mediaengine/bin/%Platform%/%Configuration%/*.exe
::rm -f ../../mediaengine/bin/%Platform%/%Configuration%/*.dll



cd ..\..\
rm -rf INFO-Win-Package-*
touch INFO-Win64-Package-%parent_build_number%-j%BUILD_NUMBER%-%git_commit_revision%

EXIT /B %errno%