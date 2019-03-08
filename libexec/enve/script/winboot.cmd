
:Boot
rem set MSYS_LOCATION=%ALLUSERSPROFILE%\devon\store
set STORE_LOCATION=%ALLUSERSPROFILE%\devon\store

if not exist "%STORE_LOCATION%\enve" (
    call :InstallEnve %*
) else (
    (
        echo "enve_dir=$(cygpath ^"%STORE_LOCATION%^")/enve"
        echo "exec $enve_dir/enve %*"
    ) > "%TEMP%\bootrc"
)
rem set MSYSTEM=MINGW64
rem set HOME=%USERPROFILE%
set MSYSTEM=MSYS2
set PATH=
call :EnterMsys "%STORE_LOCATION%\basic-msys64" "%TEMP%\bootrc"
goto :eof


:InstallEnve
if not exist "%STORE_LOCATION%\basic-msys64" (
    call :DownloadMsys2 "%STORE_LOCATION%"
    rename "%STORE_LOCATION%\msys64" "%STORE_LOCATION%\basic-msys64"
)
set exeBash=%STORE_LOCATION%\basic-msys64\usr\bin\bash
(
    echo "enve_url=https://github.com/ranlempow/enve/archive/master.zip"
    echo "enve_dir=$(cygpath ^"%STORE_LOCATION%^")/enve"
    echo "curl $enve_url > $tmpdir/enve.zip"
    echo "unzip $tmpdir/enve.zip -d $enve_dir"
    echo "exec $enve_dir/enve %*"
) > "%TEMP%\bootrc"
goto :eof


:EnterMsys
rem @echo off
set "MSYS_BASE=%~1"
set "MSYS_RCFILE=%~2"

if exist "%MSYS_BASE%\bin\mintty.exe" set "MSYS_BIN_PREFIX=/bin"
if exist "%MSYS_BASE%\usr\bin\mintty.exe" set "MSYS_BIN_PREFIX=/usr/bin"
if "%MSYS_BIN_PREFIX%" == "" (
    echo "MSYS_BIN_PATH not found in %MSYS_BASE%"
    goto :eof
)
set "MSYS_BIN_PATH=%MSYS_BASE%%MSYS_BIN_PREFIX%"
for /f "delims=" %%A in ('%MSYS_BIN_PATH%\uname.exe --operating-system') do set "MSYS_OS=%%A"
if "%MSYS_OS%" == "" (
    echo "MSYS_OS can not determined"
    goto :eof
)
if not exist "%MSYS_RCFILE%" (
    set "MSYS_RCFILE=%MSYS_BASE%\etc\profile"
)
if not exist "%WINDIR%\Fonts\Inconsolata-Regular.ttf" (
    echo install Inconsolata-Regular.ttf
    echo. > "%TEMP%/insfont.vbs"
    echo.Set objShell = CreateObject^("Shell.Application"^) >> "%TEMP%/insfont.vbs"
    echo.Set objFolder = objShell.Namespace^("%~dp0"^) >> "%TEMP%/insfont.vbs"
    echo.Set objFolderItem = objFolder.ParseName^("Inconsolata-Regular.ttf"^) >> "%TEMP%/insfont.vbs"
    echo.objFolderItem.InvokeVerb^("Install"^) >> "%TEMP%/insfont.vbs"

    wscript "%TEMP%/insfont.vbs"
)
if not exist "%USERPROFILE%\.minttyrc" (
    echo.BoldAsFont=-1 >> "%USERPROFILE%\.minttyrc"
    echo.Font=Inconsolata >> "%USERPROFILE%\.minttyrc"
    echo.FontHeight=12 >> "%USERPROFILE%\.minttyrc"
    echo.Columns=120 >> "%USERPROFILE%\.minttyrc"
    echo.BoldAsColour=no >> "%USERPROFILE%\.minttyrc"
    echo.CursorType=underscore >> "%USERPROFILE%\.minttyrc"
)
if "%MSYS_OS%" == "Msys" (
    set MSYS2_PATH_TYPE=strict
    set CYG_SYS_BASHRC=1
)
if not defined MSYSTEM set MSYSTEM=MSYS
start "" "%MSYS_BIN_PATH%\mintty.exe" -c "%USERPROFILE%\.minttyrc" -- "%MSYS_BIN_PREFIX%/bash" --rcfile "%MSYS_RCFILE%" -i
goto :eof
rem start "" "%mintty%" %args% -- /usr/bin/bash --login -i -c ". $(cygpath -u '%~dp0init')"


:DownloadMsys2
set "MSYS_LOCATION=%~1"

call :DownloadFile "http://www.7-zip.org/a/7z1604.msi" "%TEMP%\7z1604.msi"
call :UnpackMsi "%TEMP%\7z1604.msi" "%TEMP%\7z1604"
set "exe7z=%TEMP%\7z1604\Files\7-Zip\7z.exe"
call :DownloadFile "https://bintray.com/artifact/download/vszakats/generic/curl-7.58.0-win32-mingw.7z" ^
        "%TEMP%\curl-7.58.0.7z"
call :Un7zip "%TEMP%\curl-7.58.0.7z" "%TEMP%\curl"
set "exeCurl=%TEMP%\curl\curl-7.58.0-win32-mingw\bin\curl.exe"

call :DownloadCurl "https://sourceforge.net/projects/msys2/files/Base/x86_64/msys2-base-x86_64-20170918.tar.xz/download" ^
        "%TEMP%\msys2-base-x86_64-20170918.tar.xz"
call :Un7zip "%TEMP%\msys2-base-x86_64-20170918.tar.xz" "%TEMP%\msys.tar"
mkdir %MSYS_LOCATION%
call :Un7zip "%TEMP%\msys.tar\msys2-base-x86_64-20170918.tar" "%MSYS_LOCATION%" NoRemove
goto :eof


:DownloadFile
set "URL=%~1"
set "Location=%~2"
if exist "%Location%" del "%Location%"
@echo. > "%TEMP%\DownloadFile.vbs"
@echo.Set objXMLHTTP = CreateObject("WinHttp.WinHttpRequest.5.1") >> "%TEMP%\DownloadFile.vbs"
@echo.objXMLHTTP.open "GET", "%URL%", False >> "%TEMP%\DownloadFile.vbs"
@echo.objXMLHTTP.send() >> "%TEMP%\DownloadFile.vbs"
@echo.If objXMLHTTP.Status = 200 Then >> "%TEMP%\DownloadFile.vbs"
@echo.    Set objADOStream = CreateObject("ADODB.Stream") >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.Open >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.Type = 1 >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.Write objXMLHTTP.ResponseBody >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.Position = 0 >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.SaveToFile "%Location%" >> "%TEMP%\DownloadFile.vbs"
@echo.    objADOStream.Close >> "%TEMP%\DownloadFile.vbs"
@echo.End if >> "%TEMP%\DownloadFile.vbs"
"%TEMP%\DownloadFile.vbs"
del "%TEMP%\DownloadFile.vbs"
goto :eof

:DownloadCurl
set "URL=%~1"
set "Location=%~2"
if exist "%Location%" del "%Location%"
%exeCurl% -L -o"%Location%" "%URL%"
goto :eof

:Un7zip
set "ZipFile=%~1"
set "ExtractTo=%~2"
set "NoRemove=%~3"
if not "%NoRemove%" == "NoRemove" if exist "%ExtractTo%" rd /Q /S "%ExtractTo%"
%exe7z% x "%ZipFile%" -o"%ExtractTo%"
goto :eof

:Unzip
set "ZipFile=%~1"
set "ExtractTo=%~2"
> "%TEMP%\Unzip.vbs" (
@echo.Set objShell = CreateObject("Shell.Application")
@echo.Set FilesInZip = objShell.NameSpace("%ZipFile%").items
@echo.objShell.NameSpace("%ExtractTo%").CopyHere(FilesInZip)
)
"%TEMP%\Unzip.vbs"
del "%TEMP%\Unzip.vbs"
goto :eof


:UnpackMsi
set "MSIFile=%~1"
set "ExtractTo=%~2"
if not exist "%ExtractTo%" mkdir "%ExtractTo%"
msiexec /a "%MSIFile%" /qb TARGETDIR="%ExtractTo%"
goto :eof
