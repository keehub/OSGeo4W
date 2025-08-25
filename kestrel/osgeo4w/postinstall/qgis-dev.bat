@REM TODO kestrel 修改快捷方式名称
set APPNAME=黄陵智慧水务地理信息服务

call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
call "%OSGEO4W_ROOT%\bin\gdal-dev-py-env.bat"

if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Desktop`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

for %%i in ("%OSGEO4W_STARTMENU%") do set QGIS_WIN_APP_NAME=%%~ni\%APPNAME%
call "%OSGEO4W_ROOT%\bin\qgis-dev.bat" --postinstall
echo on

@REM if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

@REM TODO kestrel 开始菜单程序根目录
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\%APPNAME%.lnk" "%OSGEO4W_ROOT%\bin\qgis-dev-bin.exe" "" "%DOCUMENTS%"
if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\%APPNAME%.lnk" "%OSGEO4W_ROOT%\bin\qgis-dev-bin.exe" "" "%DOCUMENTS%"

@REM TODO kestrel 直接指定路径到桌面根目录
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\%APPNAME%.lnk" "%OSGEO4W_ROOT%\bin\qgis-dev-bin.exe" "" "%DOCUMENTS%"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%USERPROFILE%\Desktop\%APPNAME%.lnk" "%OSGEO4W_ROOT%\bin\qgis-dev-bin.exe" "" "%DOCUMENTS%"

@REM TODO kestrel 移除多余快捷方式
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\Qt Designer with QGIS 3.99.0 custom widgets (Nightly).lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\qgis-dev-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\qgis-dev\icons\QGIS.ico"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\Qt Designer with QGIS 3.99.0 custom widgets (Nightly).lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\qgis-dev-designer.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\qgis-dev\icons\QGIS.ico"

set O4W_ROOT=%OSGEO4W_ROOT%
set OSGEO4W_ROOT=%OSGEO4W_ROOT:\=\\%
textreplace -std -t "%O4W_ROOT%\apps\qgis-dev\bin\qgis.reg"
set OSGEO4W_ROOT=%O4W_ROOT%

REM Do not register extensions if release is installed
if not exist "%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgis.reg" if not exist "%OSGEO4W_ROOT%\apps\qgis\bin\qgis.reg" "%WINDIR%\regedit" /s "%OSGEO4W_ROOT%\apps\qgis-dev\bin\qgis.reg"

call "%OSGEO4W_ROOT%\bin\o4w_env.bat"
call "%OSGEO4W_ROOT%\bin\gdal-dev-py-env.bat"
path %PATH%;%OSGEO4W_ROOT%\apps\qgis-dev\bin
set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/qgis-dev
"%OSGEO4W_ROOT%\apps\qgis-dev\crssync"

del /s /q "%OSGEO4W_ROOT%\apps\qgis-dev\python\*.pyc"
if exist "%OSGEO4W_ROOT%\apps\qgis-dev\python\plugins\sagaprovider" rd /s /q "%OSGEO4W_ROOT%\apps\qgis-dev\python\plugins\sagaprovider"
exit /b 0
