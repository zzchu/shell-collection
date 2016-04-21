cd c:\
::cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
::rm -rf vendor\libsdp
::git submodule update --init --recursive

SET /A errno=0
echo START TO BUILD SDK
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\build\wp8
rm -f *.zip
python build_2013_wp8.py clean
python build_2013_wp8.py release
if %fast_mode%==no (python build_2013_wp8.py debug)
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
echo START TO PACKAGE SDK
python package.py release
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
mv \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\distribution\WP8\wme-wp8-release.zip .\MediaSDK_Demo_WinPhone8.zip

echo START TO BUILD REF-APP
cd \Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\ta\ref-app\WP8\buildscript
python refapp_build_wp8.py clean
python refapp_build_wp8.py release
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

EXIT /B %errno%