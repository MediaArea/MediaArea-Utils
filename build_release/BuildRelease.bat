@echo off

rem ***********************************************************************************************
rem * You need Visual Studio 2015 and Git installed at default places                             *
rem * You need Embarcadero RAD Studio 9 installed at default place for official MediaInfo GUI     *
rem * You need (Project)-AllInOne, MediaArea-Utils, MediaArea-Utils-Binaries repos                *
rem * Code signing certificate is expected to be in %USERPROFILE%\CodeSigningCertificate.p12      *
rem * Code signing password is expected to be in %USERPROFILE%\CodeSigningCertificate.pass        *
rem * Patch for MediaInfo donors is expected to be in %USERPROFILE%\MediaInfo_Donors.diff         *
rem *                                                                                             *
rem * Command line options:                                                                       *
rem * - MC or MediaConch: Build MediaConch                                                        *
rem * - MI or MediaInfo: Build MediaInfo                                                          *
rem * - /archive: Build from an archive "*_AllInclusive.7z" instead of git repository             *
rem * - /nosign: Do not try to sign executables                                                   *
rem ***********************************************************************************************

rem *** Init ***
set ERRORLEVEL=
set BUILD_RELEASE_ERRORCODE=
set BUILD_MC=
set BUILD_MI=
set ARCHIVE=
set NOSIGN=

if EXIST Release\ call:Rtree Release\ || exit /b 1

mkdir Release\ || exit /b 1
mkdir Release\download\ || exit /b 1
mkdir Release\download\binary\ || exit /b 1

if EXIST ThankYou call:Rtree ThankYou\ || exit /b 1

rem *** Handling of paths for 64-bit compilation ***
set OLD_PATH=%PATH%
set OLD_CD=%CD%
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
set PATH=%PATH%;"C:\Program Files\Git\bin"

rem *** Parse command line ***

:Cmdline
if not "%1"=="" (
    if /I "%1"=="MediaConch" set BUILD_MC=1
    if /I "%1"=="MC" set BUILD_MC=1
    if /I "%1"=="MediaInfo" set BUILD_MI=1
    if /I "%1"=="MI" set BUILD_MI=1
    if /I "%1"=="/archive" set ARCHIVE=1
    if /I "%1"=="/nosign" set NOSIGN=1
    shift
    GOTO:Cmdline
)

rem *** Handling projects ***
if "%BUILD_MC%"=="1"    call:MediaConch   || set BUILD_RELEASE_ERRORCODE=1
if "%BUILD_MI%"=="1"    call:MediaInfo    || set BUILD_RELEASE_ERRORCODE=1
if "%BUILD_MC%"=="" if "%BUILD_MI%"=="" (
                        call:MediaConch   || set BUILD_RELEASE_ERRORCODE=1
                        call:MediaInfo    || set BUILD_RELEASE_ERRORCODE=1
)

cd %OLD_CD%
set PATH=%OLD_PATH%
if "%BUILD_RELEASE_ERRORCODE%"=="1" echo Problem && exit /b 1
GOTO:EOF

rem *** Global Helpers ***

:Rtree
rem buggy rmdir sometimes does not delete all files and directories
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 timeout /t 3
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 timeout /t 3
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 timeout /t 3
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 rmdir %~1 /s /q
if EXIST %~1 timeout /t 3
if EXIST %~1 exit /b 1
GOTO:EOF

:Patch
cd %OLD_CD%\..\..\%~1\%~2
if "%~3" NEQ "" echo Patch: %~2_%~3 && git apply --ignore-whitespace "%OLD_CD%\Diff\%~2_%~3.diff" || exit /b 1
if "%~4" NEQ "" echo Patch: %~2_%~4 && git apply --ignore-whitespace "%OLD_CD%\Diff\%~2_%~4.diff" || exit /b 1
if "%~5" NEQ "" echo Patch: %~2_%~5 && git apply --ignore-whitespace "%OLD_CD%\Diff\%~2_%~5.diff" || exit /b 1
if "%~6" NEQ "" echo Patch: %~2_%~6 && git apply --ignore-whitespace "%OLD_CD%\Diff\%~2_%~6.diff" || exit /b 1
GOTO:EOF

:RPatch
cd %OLD_CD%\..\..\%~1\%~2
if "%~3" NEQ "" echo Reverse Patch: %~2_%~3 && git apply --ignore-whitespace -R "%OLD_CD%\Diff\%~2_%~3.diff" || exit /b 1
if "%~4" NEQ "" echo Reverse Patch: %~2_%~4 && git apply --ignore-whitespace -R "%OLD_CD%\Diff\%~2_%~4.diff" || exit /b 1
if "%~5" NEQ "" echo Reverse Patch: %~2_%~5 && git apply --ignore-whitespace -R "%OLD_CD%\Diff\%~2_%~5.diff" || exit /b 1
if "%~6" NEQ "" echo Reverse Patch: %~2_%~6 && git apply --ignore-whitespace -R "%OLD_CD%\Diff\%~2_%~6.diff" || exit /b 1
GOTO:EOF

rem ***********************************************************************************************
rem * MediaConch                                                                                  *
rem ***********************************************************************************************

:MediaConch

rem *** Set sources path ***
set MC_SOURCES=MediaConch-AllInOne
if "%ARCHIVE%"=="1" (
    set MC_SOURCES=mediaconch_AllInclusive
    cd %OLD_CD%\..\..
    if EXIST mediaconch_AllInclusive\ call:RTree mediaconch_AllInclusive\ || exit /b 1
    MediaArea-Utils-Binaries\Windows\7-Zip\7z x -y "mediaconch_*_AllInclusive.7z" > nul || exit /b 1
    del /q /s mediaconch_AllInclusive\.git 2> nul
)

rem *** Update git repository ***
if "%ARCHIVE%"=="" (
    cd ..\..\%MC_SOURCES%
    git submodule foreach git reset --hard HEAD
    git submodule foreach git clean -f
    git submodule update --init --remote
    cd %OLD_CD%
)

rem *** Retrieve version number ***
cd %OLD_CD%
for /F "delims=" %%a in ('find "define PRODUCT_VERSION " ..\..\%MC_SOURCES%\MediaConch\Source\Install\MediaConch_GUI_Windows.nsi') do set "Version=%%a"
set Version=%Version:!define PRODUCT_VERSION "=%
set Version=%Version:"=%

rem *** MediaConch CLI and Server ***
call:Patch_MediaConch
cd ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1
cd %OLD_CD%

rem *** MediaConch GUI ***
call:Patch_MediaConch_GUI
if EXIST ..\..\%MC_SOURCES%\Qt5.6-msvc2015\ call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015\ || exit /b 1
if EXIST ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\ call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\ || exit /b 1
xcopy /S /Q ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015 ..\..\%MC_SOURCES%\Qt5.6-msvc2015\ || exit /b 1
xcopy /S /Q ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015_64 ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\ || exit /b 1
timeout /t 3
cd ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32
timeout /t 3
if %ERRORLEVEL% NEQ 0 (
    cd %OLD_CD%
    call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015\
    call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\
    exit /b 1
)
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64
timeout /t 3
if %ERRORLEVEL% NEQ 0 (
    cd %OLD_CD%
    call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015\
    call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\
    exit /b 1
)
cd %OLD_CD%
call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015\
call:RTree ..\..\%MC_SOURCES%\Qt5.6-msvc2015_64\

rem *** libcurl ***
cd %OLD_CD%
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\Win32\Release\* ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\Win32\Release\ || exit /b 1
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\x64\Release\* ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\x64\Release\ || exit /b 1

rem *** Signature of executables ***
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
if "%NOSIGN%"=="" (
    cd %OLD_CD%
    signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\Win32\Release\MediaConch-Server.exe ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\x64\Release\MediaConch-Server.exe ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\Win32\Release\MediaConch.exe ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\x64\Release\MediaConch.exe ..\..\%MC_SOURCES%\MediaConch\Project\MSVC2015\win32\Release\MediaConch-GUI.exe || set CodeSigningCertificatePass= && exit /b 1
)
set CodeSigningCertificatePass=

rem *** Packages ***
cd ..\..\%MC_SOURCES%\MediaConch\Release
call Release_CLI_Windows_i386.bat
call Release_CLI_Windows_x64.bat
call Release_Server_Windows_i386.bat
call Release_Server_Windows_x64.bat
call Release_GUI_Windows_i386.bat
call Release_GUI_Windows_x64.bat
call Release_GUI_Windows.bat

rem *** Signature of installers ***
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
if "%NOSIGN%"=="" (
    cd %OLD_CD%
    signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe || set CodeSigningCertificatePass= && exit /b 1
)
set CodeSigningCertificatePass=

rem *** copy everything at the same place ***
cd %OLD_CD%
mkdir Release\download\binary\mediaconch\ || exit /b 1
mkdir Release\download\binary\mediaconch\%Version%\ || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_CLI_Windows_i386.zip Release\download\binary\mediaconch\%Version%\MediaConch_CLI_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_CLI_Windows_x64.zip Release\download\binary\mediaconch\%Version%\MediaConch_CLI_%Version%_Windows_x64.zip || exit /b 1
mkdir Release\download\binary\mediaconch-gui\ || exit /b 1
mkdir Release\download\binary\mediaconch-gui\%Version%\ || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe Release\download\binary\mediaconch-gui\%Version%\ || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_GUI_Windows_i386_WithoutInstaller.7z Release\download\binary\mediaconch-gui\%Version%\MediaConch_GUI_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_GUI_Windows_x64_WithoutInstaller.7z Release\download\binary\mediaconch-gui\%Version%\MediaConch_GUI_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
mkdir Release\download\binary\mediaconch-server\ || exit /b 1
mkdir Release\download\binary\mediaconch-server\%Version%\ || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_Server_Windows_i386.zip Release\download\binary\mediaconch-server\%Version%\MediaConch_Server_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\%MC_SOURCES%\MediaConch\Release\MediaConch_Server_Windows_x64.zip Release\download\binary\mediaconch-server\%Version%\MediaConch_Server_%Version%_Windows_x64.zip || exit /b 1

rem *** Reset ***
GOTO:EOF

rem *** Helpers ***

:Patch_MediaConch
call:Patch %MC_SOURCES% jansson MT
call:Patch %MC_SOURCES% libevent MT
call:Patch %MC_SOURCES% libxml2 MT
call:Patch %MC_SOURCES% libxslt MT
call:Patch %MC_SOURCES% MediaConch MT
call:Patch %MC_SOURCES% MediaInfoLib MP MT
call:Patch %MC_SOURCES% ZenLib MT
call:Patch %MC_SOURCES% zlib MT
GOTO:EOF

:Patch_MediaConch_GUI
call:RPatch %MC_SOURCES% jansson MT
call:RPatch %MC_SOURCES% libevent MT
call:RPatch %MC_SOURCES% libxml2 MT
call:RPatch %MC_SOURCES% libxslt MT
call:RPatch %MC_SOURCES% MediaConch MT
call:RPatch %MC_SOURCES% MediaInfoLib MT MP
call:RPatch %MC_SOURCES% ZenLib MT
call:RPatch %MC_SOURCES% zlib MT
call:Patch %MC_SOURCES% MediaConch MD
call:Patch %MC_SOURCES% MediaInfoLib MP
GOTO:EOF

rem ***********************************************************************************************
rem * MediaInfo                                                                                   *
rem ***********************************************************************************************

:MediaInfo

rem *** Set sources path ***
set MI_SOURCES=MediaInfo-AllInOne
if "%ARCHIVE%"=="1" (
    set MI_SOURCES=mediainfo_AllInclusive
    cd %OLD_CD%\..\..
    if EXIST mediainfo_AllInclusive\ call:Rtree mediainfo_AllInclusive\ || exit /b 1
    MediaArea-Utils-Binaries\Windows\7-Zip\7z x -y mediainfo_*_AllInclusive.7z > nul || exit /b 1
    del /q /s mediainfo_AllInclusive\.git 2> nul
)

rem *** Update git repository ***
if "%ARCHIVE%"=="" (
    cd ..\..\%MI_SOURCES%
    git submodule foreach git reset --hard HEAD
    git submodule foreach git clean -f
    git submodule update --init --remote
    cd %OLD_CD%
)

rem *** Retrieve version number ***
cd %OLD_CD%
for /F "delims=" %%a in ('find "define PRODUCT_VERSION " ..\..\%MI_SOURCES%\MediaInfo\Source\Install\MediaInfo_GUI_Windows.nsi') do set "Version=%%a"
set Version=%Version:!define PRODUCT_VERSION "=%
set Version=%Version:"=%

rem *** MediaInfo global ***
call:Patch_MediaInfo || exit /b 1

rem *** MediaInfoLib ***
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfoLib\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1

rem *** MediaInfo ***
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfo\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 || exit /b 1
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64 || exit /b 1
call set PATH_TEMP=%PATH%
if EXIST "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat" (
    call "C:\Program Files (x86)\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"
) else (
    call rsvars.bat
)
cd %OLD_CD%\..\..\%MI_SOURCES%\zlib\contrib\BCB && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 zlib.cbproj || exit /b 1
cd %OLD_CD%\..\..\%MI_SOURCES%\ZenLib\Project\BCB\Library && MSBuild /maxcpucount:1 /p:Configuration=Release;Platform=Win32 /verbosity:quiet ZenLib.cbproj || exit /b 1
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfoLib\Project\BCB\Library && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 MediaInfoLib.cbproj || exit /b 1
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfoLib\Project\BCB\Dll && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 MediaInfo_i386.cbproj || exit /b 1
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfo\Project\BCB\GUI && MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32 /t:Build MediaInfo_GUI.cbproj || exit /b 1
call set PATH=%PATH_TEMP%
call set PATH_TEMP=

rem *** Signature of executables ***
call set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
if "%NOSIGN%"=="" (
    cd %OLD_CD%
    signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaInfo /du http://mediaarea.net ..\..\%MI_SOURCES%\MediaInfoLib\Project\MSVC2015\Win32\Release\MediaInfo.dll ..\..\%MI_SOURCES%\MediaInfoLib\Project\MSVC2015\x64\Release\MediaInfo.dll ..\..\%MI_SOURCES%\MediaInfo\Project\MSVC2015\Win32\Release\MediaInfo.exe ..\..\%MI_SOURCES%\MediaInfoLib\Project\MSVC2015\Win32\Release\MediaInfo_InfoTip.dll ..\..\%MI_SOURCES%\MediaInfoLib\Project\MSVC2015\x64\Release\MediaInfo_InfoTip.dll  ..\..\%MI_SOURCES%\MediaInfo\Project\MSVC2015\x64\Release\MediaInfo.exe ..\..\%MI_SOURCES%\MediaInfo\Project\BCB\GUI\win32\Release\MediaInfo_GUI.exe || set CodeSigningCertificatePass= && exit /b 1
)
call set CodeSigningCertificatePass=

rem *** Packages ***
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfo\Release
call Release_CLI_Windows_i386.bat
call Release_CLI_Windows_x64.bat
call Release_GUI_Windows_i386.bat
call Release_GUI_Windows_x64.bat

if EXIST "%USERPROFILE%\MediaInfo_Donors.diff" (
    copy /y ..\Source\Install\MediaInfo_GUI_Windows.nsi ..\Source\Install\MediaInfo_GUI_Windows.nsi.orig || exit /b 1
    cd .. || exit /b 1
    git apply --ignore-whitespace "%USERPROFILE%\MediaInfo_Donors.diff" || exit /b 1
    cd Release || exit /b 1
    call Release_GUI_Windows.bat || exit /b 1
    move MediaInfo_GUI_%Version%_Windows.exe MediaInfo_GUI_%Version%_Windows_ThankYou.exe || exit /b 1
    move /y ..\Source\Install\MediaInfo_GUI_Windows.nsi.orig ..\Source\Install\MediaInfo_GUI_Windows.nsi || exit /b 1
)

call Release_GUI_Windows.bat
cd %OLD_CD%\..\..\%MI_SOURCES%\MediaInfoLib\Release
call Release_DLL_Windows_i386.bat
call Release_DLL_Windows_x64.bat

rem *** Signature of installers ***
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
if "%NOSIGN%"=="" (
    cd %OLD_CD%
    signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaInfo /du http://mediaarea.net ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_i386.exe ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_x64.exe ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows.exe ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows_ThankYou.exe || set CodeSigningCertificatePass= && exit /b 1
)
set CodeSigningCertificatePass=

rem *** copy everything at the same place ***
cd %OLD_CD%
mkdir ThankYou\ || exit /b 1
mkdir ThankYou\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows_ThankYou.exe ThankYou\%Version%\MediaInfo_GUI_%Version%_Windows.exe || exit /b 1
mkdir Release\download\binary\mediainfo\ || exit /b 1
mkdir Release\download\binary\mediainfo\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_CLI_Windows_i386.zip Release\download\binary\mediainfo\%Version%\MediaInfo_CLI_%Version%_Windows_i386.zip || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_CLI_Windows_x64.zip Release\download\binary\mediainfo\%Version%\MediaInfo_CLI_%Version%_Windows_x64.zip || exit /b 1
mkdir Release\download\binary\mediainfo-gui\ || exit /b 1
mkdir Release\download\binary\mediainfo-gui\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_%Version%_Windows.exe Release\download\binary\mediainfo-gui\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_Windows_i386_WithoutInstaller.7z Release\download\binary\mediainfo-gui\%Version%\MediaInfo_GUI_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfo\Release\MediaInfo_GUI_Windows_x64_WithoutInstaller.7z Release\download\binary\mediainfo-gui\%Version%\MediaInfo_GUI_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
mkdir Release\download\binary\libmediainfo0\ || exit /b 1
mkdir Release\download\binary\libmediainfo0\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_Windows_i386_WithoutInstaller.7z Release\download\binary\libmediainfo0\%Version%\MediaInfo_DLL_%Version%_Windows_i386_WithoutInstaller.7z || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_i386.exe Release\download\binary\libmediainfo0\%Version%\ || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_Windows_x64_WithoutInstaller.7z Release\download\binary\libmediainfo0\%Version%\MediaInfo_DLL_%Version%_Windows_x64_WithoutInstaller.7z || exit /b 1
copy ..\..\%MI_SOURCES%\MediaInfoLib\Release\MediaInfo_DLL_%Version%_Windows_x64.exe Release\download\binary\libmediainfo0\%Version%\ || exit /b 1

rem *** Reset ***
GOTO:EOF

rem *** Helpers ***

:Patch_MediaInfo
call:Patch %MI_SOURCES% MediaInfo Log MT XP NoGUI || exit /b 1
call:Patch %MI_SOURCES% MediaInfoLib MP MT XP || exit /b 1
call:Patch %MI_SOURCES% ZenLib MT XP || exit /b 1
call:Patch %MI_SOURCES% zlib MT XP || exit /b 1
GOTO:EOF
