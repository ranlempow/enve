@TODO: need research
@ref: https://github.com/ternaris/bootstrap-cygwin/blob/master/bootstrap-cygwin.bat

@echo off
@echo.
@echo WARNING: Do not run this on a production machine!
@echo.

rem The drive and directory of the file being executed.
%~d0
cd "%~dp0"

set DRIVE=c:
set CACHEDIR=%DRIVE%\cygwin-cache

rem Use your custom mirror here
set MIRROR=http://ftp.gwdg.de/pub/linux/sources.redhat.com/cygwin/

:SARCH
set ARCH=""
set /p ARCH=" What architecture (x86/x86_64)? "
if "%ARCH%" == "x86" goto SARCHOK
if "%ARCH%" == "x86_64" goto SARCHOK
goto SARCH
:SARCHOK
set SETUPEXE=setup-%ARCH%.exe

set SUFFIX=""
set /p SUFFIX=" cygwin target directory suffix? "

if "%SUFFIX%" equ "" (
    set NAME=cygwin-%ARCH%
) else (
    set NAME=cygwin-%ARCH%-%SUFFIX%
)

set TARGETDIR=%DRIVE%\%NAME%
if exist "%TARGETDIR%" (
    echo "%TARGETDIR%" exists already, not going to overwrite.
    pause
    exit /B
)
set BASH=%TARGETDIR%\bin\bash

"%SETUPEXE%" -q -X -O -s %MIRROR% -R "%TARGETDIR%" -l "%CACHEDIR%" -P bison,curl,flex,cygport,git,git-completion,libbz2-devel,libcrypt-devel,libcurl-devel,libsqlite3-devel,openssh,openssl-devel,perl-DBD-SQLite,pkg-config,tmux,vim,wget

@echo.
echo Please wait until the cygwin installer has finished, then press any key to continue;
@echo.
pause

copy "%SETUPEXE%" "%TARGETDIR%"
xcopy /s /y skel "%TARGETDIR%\etc\skel"

rem Kill Cygwin's Python, as it interferes with Nix' Python
rem move "%TARGETDIR%\bin\libpython2.7.dll" "%TARGETDIR%\bin\libpython2.7.dll-DO-NOT-USE-ME"

> "%TARGETDIR%\mintty.bat" (
    @echo start "" "%%~dp0bin\mintty.exe" -
)
> "%TARGETDIR%\setup.bat" (
    @echo "%%~dp0%SETUPEXE%" -q -X -O -s %MIRROR% -R "%TARGETDIR%" -l "%CACHEDIR%" %%*
)

@echo.
@echo Your cygwin is at "%TARGETDIR%\mintty"
@echo.
pause
