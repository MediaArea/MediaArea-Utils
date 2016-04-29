@echo off

rem ***********************************************************************************************
rem * You need Visual Studio 2015 and Git installed at default places                             *
rem * You need Embarcadero RAD Studio 9 installed at default place for official MediaInfo GUI     *
rem * You need (Project)-AllInOne, MediaArea-Utils, MediaArea-Utils-Binaries repos                *
rem * Code signing certificate is expected to be in %USERPROFILE%\CodeSigningCertificate.p12      *
rem * Code signing password is expected to be in %USERPROFILE%\CodeSigningCertificate.pass        *
rem * Patch for MediaInfo donors is expected to be in %USERPROFILE%\MediaInfo_Donors.diff         *
rem ***********************************************************************************************



rem *** Init ***
set ERRORLEVEL=
set BUILD_RELEASE_ERRORCODE=
if EXIST Release\ (
    rmdir Release\ /S /Q || exit /b 1
    rem sometimes the mkdir just after the rmdir fails
    timeout /t 3
)
mkdir Release\ || exit /b 1
mkdir Release\download\ || exit /b 1
mkdir Release\download\binary\ || exit /b 1
if EXIST ThankYou\ (
    rmdir ThankYou\ /S /Q || exit /b 1
    rem sometimes the mkdir just after the rmdir fails
    timeout /t 3
)

rem *** Handling of paths for 64-bit compilation ***
set OLD_PATH=%PATH%
set OLD_CD=%CD%
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
set PATH=%PATH%;"C:\Program Files\Git\bin"

rem *** Handling projects ***
if /I "%1"=="MediaConch"    call:MediaConch     || set BUILD_RELEASE_ERRORCODE=1
if /I "%1"=="MC"            call:MediaConch     || set BUILD_RELEASE_ERRORCODE=1
if /I "%1"=="MediaInfo"     call:MediaInfo      || set BUILD_RELEASE_ERRORCODE=1
if /I "%1"=="MI"            call:MediaInfo      || set BUILD_RELEASE_ERRORCODE=1
if "%1"=="" (
                            call:MediaConch     || set BUILD_RELEASE_ERRORCODE=1
                            call:MediaInfo      || set BUILD_RELEASE_ERRORCODE=1
)
cd %OLD_CD%
set PATH=%OLD_PATH%
if "%BUILD_RELEASE_ERRORCODE%"=="1" echo Problem && exit /b 1
GOTO:EOF

rem *** Global Helpers ***

:Patch
cd ..\..\%~1-AllInOne\%~2
git reset --hard HEAD
if "%~3" NEQ "" echo Git: %~2_%~3 && git apply "%OLD_CD%\Diff\%~2_%~3.diff" || exit /b 1
if "%~4" NEQ "" echo Git: %~2_%~4 && git apply "%OLD_CD%\Diff\%~2_%~4.diff" || exit /b 1
if "%~5" NEQ "" echo Git: %~2_%~5 && git apply "%OLD_CD%\Diff\%~2_%~5.diff" || exit /b 1
if "%~6" NEQ "" echo Git: %~2_%~6 && git apply "%OLD_CD%\Diff\%~2_%~6.diff" || exit /b 1
GOTO:EOF

rem ***********************************************************************************************
rem * MediaConch                                                                                  *
rem ***********************************************************************************************

:MediaConch

rem *** Retrieve version number ***
cd %OLD_CD%
for /F "delims=" %%a in ('find "define PRODUCT_VERSION " ..\..\MediaConch-AllInOne\MediaConch\Source\Install\MediaConch_GUI_Windows.nsi') do set "Version=%%a"
set Version=%Version:!define PRODUCT_VERSION "=%
set Version=%Version:"=%

rem *** MediaConch CLI and Server ***
call:Patch_MediaConch
cd ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1
cd %OLD_CD%

rem *** MediaConch GUI ***
call:Patch_MediaConch_GUI
if EXIST ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\ rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\ || exit /b 1
if EXIST ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\ rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\ || exit /b 1
xcopy /S /Q ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015 ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\ || exit /b 1
xcopy /S /Q ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015_64 ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\ || exit /b 1
cd ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32
if %ERRORLEVEL% NEQ 0 (
    cd %OLD_CD%
    rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\
    rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\
    exit /b 1
)
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64
if %ERRORLEVEL% NEQ 0 (
    cd %OLD_CD%
    rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\
    rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\
    exit /b 1
)
cd %OLD_CD%
rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015\
rmdir /S /Q ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64\

rem *** libcurl ***
cd %OLD_CD%
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\Win32\Release\* ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\ || exit /b 1
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\x64\Release\* ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\ || exit /b 1

rem *** Signature of executables ***
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\MediaConch-Server.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\MediaConch-Server.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\MediaConch.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\MediaConch.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\win32\Release\MediaConch-GUI.exe || set CodeSigningCertificatePass= && exit /b 1
set CodeSigningCertificatePass=

rem *** Packages ***
cd ..\..\MediaConch-AllInOne\MediaConch\Release
call Release_CLI_Windows_i386.bat
call Release_CLI_Windows_x64.bat
call Release_Server_Windows_i386.bat
call Release_Server_Windows_x64.bat
call Release_GUI_Windows_i386.bat
call Release_GUI_Windows_x64.bat
call Release_GUI_Windows.bat

rem *** Signature of installers ***
cd %OLD_CD%
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe || set CodeSigningCertificatePass= && exit /b 1
set CodeSigningCertificatePass=

rem *** copy everything at the same place ***
cd %OLD_CD%
mkdir Release\download\binary\mediaconch\ || exit /b 1
mkdir Release\download\binary\mediaconch\%Version%\ || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_CLI_Windows_i386.zip Release\download\binary\mediaconch\%Version%\MediaConch_CLI_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_CLI_Windows_x64.zip Release\download\binary\mediaconch\%Version%\MediaConch_CLI_%Version%_Windows_x64.zip || exit /b 1
mkdir Release\download\binary\mediaconch-gui\ || exit /b 1
mkdir Release\download\binary\mediaconch-gui\%Version%\ || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe Release\download\binary\mediaconch-gui\%Version%\ || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_Windows_i386_WithoutInstaller.7z Release\download\binary\mediaconch-gui\%Version%\MediaConch_Server_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_Windows_x64_WithoutInstaller.7z Release\download\binary\mediaconch-gui\%Version%\MediaConch_Server_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
mkdir Release\download\binary\mediaconch-server\ || exit /b 1
mkdir Release\download\binary\mediaconch-server\%Version%\ || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_Server_Windows_i386.zip Release\download\binary\mediaconch-server\%Version%\MediaConch_Server_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_Server_Windows_x64.zip Release\download\binary\mediaconch-server\%Version%\MediaConch_Server_%Version%_Windows_x64.zip || exit /b 1

rem *** Reset ***
GOTO:EOF

rem *** Helpers ***

:Patch_MediaConch
call:Patch MediaConch jansson MT
call:Patch MediaConch libevent MT
call:Patch MediaConch libxml2 MT
call:Patch MediaConch libxslt MT
call:Patch MediaConch MediaConch MT
call:Patch MediaConch MediaInfoLib MP MT
call:Patch MediaConch ZenLib MT
call:Patch MediaConch zlib MT
GOTO:EOF

:Patch_MediaConch_GUI
call:Patch MediaConch jansson
call:Patch MediaConch libevent
call:Patch MediaConch libxml2
call:Patch MediaConch libxslt
call:Patch MediaConch MediaConch MD
call:Patch MediaConch MediaInfoLib MP
call:Patch MediaConch ZenLib
call:Patch MediaConch zlib
GOTO:EOF

rem ***********************************************************************************************
rem * MediaInfo                                                                                  *
rem ***********************************************************************************************

:MediaInfo

rem *** Retrieve version number ***
cd %OLD_CD%
for /F "delims=" %%a in ('find "define PRODUCT_VERSION " ..\..\MediaInfo-AllInOne\MediaInfo\Source\Install\MediaInfo_GUI_Windows.nsi') do set "Version=%%a"
set Version=%Version:!define PRODUCT_VERSION "=%
set Version=%Version:"=%

rem *** MediaInfo global ***
call:Patch_MediaInfo || exit /b 1

rem *** MediaInfoLib ***
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfoLib\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1

rem *** MediaInfo ***
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfo\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1
call set PATH_TEMP=%PATH%
call "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"
cd %OLD_CD%\..\..\MediaInfo-AllInOne\zlib\contrib\BCB && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 zlib.cbproj || exit /b 1
cd %OLD_CD%\..\..\MediaInfo-AllInOne\ZenLib\Project\BCB\Library && MSBuild /maxcpucount:1 /p:Configuration=Release;Platform=Win32 /verbosity:quiet ZenLib.cbproj || exit /b 1
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfoLib\Project\BCB\Library && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 MediaInfoLib.cbproj || exit /b 1
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfoLib\Project\BCB\Dll && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 MediaInfo_i386.cbproj || exit /b 1
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfo\Project\BCB\GUI && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 /t:Build MediaInfo_GUI.cbproj || exit /b 1
call set PATH=%PATH_TEMP%
call set PATH_TEMP=

rem *** Signature of executables ***
cd %OLD_CD%
call set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaInfo /du http://mediaarea.net ..\..\MediaInfo-AllInOne\MediaInfoLib\Project\MSVC2015\Win32\Release\MediaInfo.dll ..\..\MediaInfo-AllInOne\MediaInfoLib\Project\MSVC2015\x64\Release\MediaInfo.dll ..\..\MediaInfo-AllInOne\MediaInfo\Project\MSVC2015\Win32\Release\MediaInfo.exe ..\..\MediaInfo-AllInOne\MediaInfoLib\Project\MSVC2015\Win32\Release\MediaInfo_InfoTip.dll ..\..\MediaInfo-AllInOne\MediaInfoLib\Project\MSVC2015\x64\Release\MediaInfo_InfoTip.dll  ..\..\MediaInfo-AllInOne\MediaInfo\Project\MSVC2015\x64\Release\MediaInfo.exe ..\..\MediaInfo-AllInOne\MediaInfo\Project\BCB\GUI\win32\Release\MediaInfo_GUI.exe || set CodeSigningCertificatePass= && exit /b 1
call set CodeSigningCertificatePass=

rem *** Packages ***
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfo\Release
call Release_CLI_Windows_i386.bat
call Release_CLI_Windows_x64.bat
call Release_GUI_Windows_i386.bat
call Release_GUI_Windows_x64.bat
cd ..
git apply --ignore-whitespace "%USERPROFILE%\MediaInfo_Donors.diff" || exit /b 1
cd Release || exit /b 1
call Release_GUI_Windows.bat || exit /b 1
move MediaInfo_GUI_%Version%_Windows.exe MediaInfo_GUI_%Version%_Windows_ThankYou.exe || exit /b 1
git reset ..\Source\Install\MediaInfo_GUI_Windows.nsi || exit /b 1
call Release_GUI_Windows.bat
cd %OLD_CD%\..\..\MediaInfo-AllInOne\MediaInfoLib\Release
call Release_DLL_Windows_i386.bat
call Release_DLL_Windows_x64.bat

rem *** Signature of installers ***
cd %OLD_CD%
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaInfo /du http://mediaarea.net ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_i386.exe ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_x64.exe ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows.exe ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows_ThankYou.exe || set CodeSigningCertificatePass= && exit /b 1
set CodeSigningCertificatePass=

rem *** copy everything at the same place ***
cd %OLD_CD%
mkdir ThankYou\ || exit /b 1
mkdir ThankYou\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows_ThankYou.exe ThankYou\%Version%\MediaInfo_GUI_%Version%_Windows.exe || exit /b 1
mkdir Release\download\binary\mediainfo\ || exit /b 1
mkdir Release\download\binary\mediainfo\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_CLI_Windows_i386.zip Release\download\binary\mediainfo\%Version%\MediaInfo_CLI_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_CLI_Windows_x64.zip Release\download\binary\mediainfo\%Version%\MediaInfo_CLI_%Version%_Windows_x64.zip || exit /b 1
mkdir Release\download\binary\mediainfo-gui\ || exit /b 1
mkdir Release\download\binary\mediainfo-gui\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows.exe Release\download\binary\mediainfo-gui\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_Windows_i386_WithoutInstaller.7z Release\download\binary\mediainfo-gui\%Version%\MediaInfo_GUI_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfo\Release\MediaInfo_GUI_Windows_x64_WithoutInstaller.7z Release\download\binary\mediainfo-gui\%Version%\MediaInfo_GUI_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
mkdir Release\download\binary\libmediainfo0\ || exit /b 1
mkdir Release\download\binary\libmediainfo0\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_Windows_i386_WithoutInstaller.7z Release\download\binary\libmediainfo0\%Version%\MediaInfo_DLL_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_i386.exe Release\download\binary\libmediainfo0\%Version%\ || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_Windows_x64_WithoutInstaller.7z Release\download\binary\libmediainfo0\%Version%\MediaInfo_DLL_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
copy ..\..\MediaInfo-AllInOne\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_x64.exe Release\download\binary\libmediainfo0\%Version%\ || exit /b 1

rem *** Reset ***
GOTO:EOF

rem *** Helpers ***

:Patch_MediaInfo
call:Patch MediaInfo MediaInfo Log MT XP NoGUI || exit /b 1
call:Patch MediaInfo MediaInfoLib MP MT XP || exit /b 1
call:Patch MediaInfo ZenLib MT XP || exit /b 1
call:Patch MediaInfo zlib MT XP || exit /b 1
GOTO:EOF
