@echo off

rem ***********************************************************************************************
rem * You need Visual Studio 2015 and Git installed at default places                             *
rem * You need (Project)-AllInOne, MediaArea-Utils, MediaArea-Utils-Binaries repos                *
rem * Code signing certificate is expected to be in %USERPROFILE%\CodeSigningCertificate.p12      *
rem * Code signing password is expected to be in %USERPROFILE%\CodeSigningCertificate.pass        *
rem ***********************************************************************************************



rem *** Init ***
set ERRORLEVEL=

rem *** Handling of paths for 64-bit compilation ***
set OLD_PATH=%PATH%
set OLD_CD=%CD%
call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
set PATH=%PATH%;"C:\Program Files\Git\bin"

rem *** Handling projects ***
if /I "%1"=="MediaConch" (
    call:MediaConch
    exit /b %ERRORLEVEL%
)
if /I "%1"=="MC" (
    call:MediaConch
    exit /b %ERRORLEVEL%
)
if "%1"=="" (
    call:MediaConch
    exit /b %ERRORLEVEL%
)
echo Error
GOTO:EOF

rem *** Global Helpers ***

:Patch
cd ..\..\%~1-AllInOne\%~2
git reset --hard HEAD
if "%~3" NEQ "" git apply "%OLD_CD%\Diff\%~2_%~3.diff"
if "%~4" NEQ "" git apply "%OLD_CD%\Diff\%~2_%~4.diff"
cd %OLD_CD%
GOTO:EOF

rem ***********************************************************************************************
rem * MediaConch                                                                                  *
rem ***********************************************************************************************

:MediaConch

rem *** Retrieve version number ***
for /F "delims=" %%a in ('find "define PRODUCT_VERSION " ..\..\MediaConch-AllInOne\MediaConch\Source\Install\MediaConch_GUI_Windows.nsi') do set "Version=%%a"
set Version=%Version:!define PRODUCT_VERSION "=%
set Version=%Version:"=%

rem *** MediaConch CLI and Server ***
call:Patch_MediaConch
cd ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32
if %ERRORLEVEL% NEQ 0 (
    echo MSBuild failure
    cd %OLD_CD%
    exit /b %ERRORLEVEL%
)
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64
if %ERRORLEVEL% NEQ 0 (
    echo MSBuild failure
    cd %OLD_CD%
    exit /b %ERRORLEVEL%
)
cd %OLD_CD%

rem *** MediaConch GUI ***
call:Patch_MediaConch_GUI
move ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015 ..\..\MediaConch-AllInOne\
move ..\..\MediaArea-Utils-Binaries\Windows\Qt\Qt5.6-msvc2015_64 ..\..\MediaConch-AllInOne\
cd ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=Win32
if %ERRORLEVEL% NEQ 0 (
    echo MSBuild failure
    cd %OLD_CD%
    move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015 ..\..\MediaArea-Utils-Binaries\Windows\Qt\
    move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64 ..\..\MediaArea-Utils-Binaries\Windows\Qt\
    exit /b %ERRORLEVEL%
)
MSBuild /maxcpucount:1 /verbosity:quiet /p:Configuration=Release;Platform=x64
if %ERRORLEVEL% NEQ 0 (
    echo MSBuild failure
    cd %OLD_CD%
    move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015 ..\..\MediaArea-Utils-Binaries\Windows\Qt\
    move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64 ..\..\MediaArea-Utils-Binaries\Windows\Qt\
    exit /b %ERRORLEVEL%
)
cd %OLD_CD%
move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015 ..\..\MediaArea-Utils-Binaries\Windows\Qt\
move ..\..\MediaConch-AllInOne\Qt5.6-msvc2015_64 ..\..\MediaArea-Utils-Binaries\Windows\Qt\

rem *** libcurl ***
cd %OLD_CD%
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\Win32\Release\* ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\
copy ..\..\MediaArea-Utils-Binaries\Windows\libcurl\x64\Release\* ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\

rem *** Signature of executables ***
set /P CodeSigningCertificatePass= < %USERPROFILE%\CodeSigningCertificate.pass
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\MediaConch-Server.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\MediaConch-Server.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\Win32\Release\MediaConch.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\x64\Release\MediaConch.exe ..\..\MediaConch-AllInOne\MediaConch\Project\MSVC2015\win32\Release\MediaConch-GUI.exe
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
signtool sign /f %USERPROFILE%\CodeSigningCertificate.p12 /p %CodeSigningCertificatePass% /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d MediaConch /du http://mediaarea.net ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe
set CodeSigningCertificatePass=

rem *** copy everything at the same place ***
cd %OLD_CD%
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_CLI_Windows_i386.zip .\MediaConch_CLI_%Version%_Windows_i386.zip
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_CLI_Windows_x64.zip .\MediaConch_CLI_%Version%_Windows_x64.zip
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_%Version%_Windows.exe
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_Windows_i386_WithoutInstaller.7z .\MediaConch_Server_%Version%_Windows_i386_WithoutInstaller.7z
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_GUI_Windows_x64_WithoutInstaller.7z .\MediaConch_Server_%Version%_Windows_x64_WithoutInstaller.7z
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_Server_Windows_i386.zip .\MediaConch_Server_%Version%_Windows_i386.zip
copy ..\..\MediaConch-AllInOne\MediaConch\Release\MediaConch_Server_Windows_x64.zip .\MediaConch_Server_%Version%_Windows_x64.zip

rem *** Reset ***
cd %OLD_CD%
set PATH=%OLD_PATH%
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


