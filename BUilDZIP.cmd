@echo off
cls
setlocal ENABLEDELAYEDEXPANSION

set "ADBOVERNETWORK_IP=192.168.1.11"
set "TARGETDIR=ufs"
set "TARGET=%TARGETDIR%.zip"
set "OUTZIP=asusStockApps_O_PUB.zip"

title %OUTZIP% BUILDER

echo.
echo.      %OUTZIP%
echo.
echo.


set "CORE=..\..\uniFlashScript\uFS\core"
set "META=..\..\uniFlashScript\uFS\META-INF"
set "TPBP=..\..\TweakPropB\uFS\install\tweak.prop"
set "TPBA=..\..\TweakPropB\uFS\install\10-tweakpropB.sh"
set "comm=..\ASA_common\o_pub\system"
set "inst=..\ASA_common\install"


if exist %TARGET% (
	del /f /q %TARGET%
)

if exist %TARGETDIR%-signed.zip (
	del /f /q %TARGETDIR%-signed.zip
)
::goto :build
if not exist %CORE% (
	echo. UNABLE TO DETECT CORE
	goto :exit
)


echo.I: COPYING CORE
xcopy /S /Y /D /J "%CORE%\*" "%~dp0%TARGETDIR%\core"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY CORE
	goto :exit
)

echo.I: COPYING META-INF
xcopy /S /Y /D /J "%META%\*" "%~dp0%TARGETDIR%\META-INF"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY META-INF
	goto :exit
)

echo.I: COPYING TWEAKPROPB ADDON ^& PROP FILE
xcopy /S /Y /D /J "%TPBA%" "%~dp0%TARGETDIR%\install\"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY TWEAKPROP ADDON FILE
	goto :exit
)
xcopy /S /Y /D /J "%TPBP%" "%~dp0%TARGETDIR%\install\"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY TWEAKPROP PROP FILE
	goto :exit
)

echo.I: COPYING INSTALL
xcopy /S /Y /D /J "%inst%\*" "%~dp0%TARGETDIR%\install"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY INSTALL
	goto :exit
)


echo.I: COPYING SYSTEM APP's
xcopy /S /Y /D /J "%comm%" "%~dp0%TARGETDIR%\system"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO COPY SYSTEM APP's
	goto :exit
)

if exist %OUTZIP% (
	del /f /q %OUTZIP%
)

if exist %OUTZIP%-signed.zip (
	del /f /q %OUTZIP%-signed.zip
)
REM exit 0
:build
echo.I: BUILDING %TARGET%
echo.I: Creating %OUTZIP%
zipbuild -md5 -signed "%TARGETDIR%"

if not exist %TARGET% (
	set "TARGETDIR=%TARGETDIR%-signed"
	set "TARGET=!TARGETDIR!.zip"
	if not exist !TARGET! (
		echo. FAILED TO BUILD ZIP
		goto :exit
	)
)

echo.I: Renaming Zip
move /Y "%~dp0%TARGET%" "%OUTZIP%"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO RENAME %OUTZIP%
	goto :exit
)
move /Y "%~dp0%TARGET%.md5" "%OUTZIP%.md5"
if %ERRORLEVEL% neq 0 (
	echo. FAILED TO RENAME %OUTZIP%.md5
	goto :exit
)

:reupload
echo.I: UPLOADING TO DEVICE VIA ADB
adb shell "echo test" >nul 2>&1
if %ERRORLEVEL% neq 0 (
	adb kill-server
	timeout 5 >nul 2>&1
	adb start-server
)
echo.I: WAITING FOR ADB...
adb connect %ADBOVERNETWORK_IP% >nul 2>&1
adb wait-for-any
adb push %OUTZIP%.md5	/sdcard
adb push %OUTZIP%		/sdcard
::adb sideload %OUTZIP%
if %ERRORLEVEL% neq 0 (
	echo.W: FAILED TO UPLOAD.. REUPLOADING...
	timeout 5 >nul 2>&1
	goto :reupload
) 
timeout 5 >nul 2>&1
echo.I: CLEANING UP...
::del /f /q %TARGET% %TARGET%.md5

:exit
echo.I: DONE..
timeout 5 >nul 2>&1
exit 0