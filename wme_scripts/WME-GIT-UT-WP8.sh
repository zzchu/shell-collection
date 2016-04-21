@echo off
set UTDir=c:\Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%\unittest\bld\wp8
set WMELocDir=c:\Users\testbed\Jenkins_Workspace\%repo_loc%\%wme_loc%
set DistributionDir=%WMELocDir%\distribution\WP8

set DolphinTestXMLFile=%UTDir%\XML_Release_DolphinTestApp\dolphin_unittest_main.xml
set SharkTestXMLFile=%UTDir%\XML_Release_SharkTestApp\shark_unittest_main.xml
set TestResultDir=%UTDir%\TestXML

set DolphinTestTraceFile=%UTDir%\Trace_Release_DolphinTestApp\DolphinTest_Trace.log
set SharkTestTraceFile=%UTDir%\Trace_Release_SharkTestApp\SharkTest_Trace.log

set TestTraceDir=%UTDir%\TestTrace


cd %WMELocDir%

echo START TO GET SDK
echo Get the WME SDK for WP8 platform
if exist %DistributionDir%   rd /s /q  %DistributionDir%
md  %DistributionDir%
cd %DistributionDir%
if %bld_wp8_url% == None (set bld_wp8_url=%UPSTREAM_URL%)
SET UPSTREAM_BASE=%bld_wp8_url%/artifact/%repo_loc%/%wme_loc%/build/wp8
curl -C - --retry 3 --retry-delay 60 -k -s -S -O -u wme-jenkins1.gen:d67f0ebb7ab2d9f33c1f96ae64c30f61 %UPSTREAM_BASE%/MediaSDK_Demo_WinPhone8.zip
7z x MediaSDK_Demo_WinPhone8.zip

echo ****************************************************
echo     distribution dlls and libs check
echo ****************************************************
dir %DistributionDir%\dlls\release
dir %DistributionDir%\libs\release
echo ****************************************************


SET /A errno=0
cd %UTDir%
echo UTDir is %UTDir%
echo current dir is :
echo %cd%

echo START TO BUILD AND RUN UT
echo **************************************************
echo       Running WP8 UT
echo **************************************************
call %UTDir%\WMEUnitTestBuildAndTest.bat  Clean-Release

date
call %UTDir%\WMEUnitTestBuildAndTest.bat  Build-Release
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

date
call %UTDir%\WMEUnitTestBuildAndTest.bat  Test-Release
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%
date

echo **************************************************
echo       Copy WP8 UT result files
echo **************************************************
if exist %TestResultDir%  rd /s /q %TestResultDir%
md %TestResultDir%
if exist %DolphinTestXMLFile% copy /y  %DolphinTestXMLFile%  %TestResultDir%
if exist %SharkTestXMLFile%   copy /y  %SharkTestXMLFile%    %TestResultDir%


echo **************************************************
echo       Copy WP8 UT trace files
echo **************************************************
if exist %TestTraceDir%  rd /s /q %TestTraceDir%
md %TestTraceDir%
if exist %DolphinTestTraceFile% copy /y  %DolphinTestTraceFile%  %TestTraceDir%
if exist %SharkTestTraceFile%   copy /y  %SharkTestTraceFile%    %TestTraceDir%
if %ERRORLEVEL% GEQ 1 SET /A errno=%ERRORLEVEL%

EXIT /B %errno%