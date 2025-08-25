set ICON=%OSGEO4W_ROOT%\apps\grass\grass84\gui\icons\grass_osgeo.ico
set BATCH=%OSGEO4W_ROOT%\bin\grass84.bat
textreplace -std -t "%BATCH%"
textreplace -std -t "%OSGEO4W_ROOT%\apps\grass\grass84\etc\fontcap"

for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

@REM TODO kestrel 移除多余快捷方式
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\GRASS GIS 8.4.1.lnk" "%BATCH%"  "--gui" "%DOCUMENTS%" "Launch GRASS GIS 8.4.1" 1 "%ICON%"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\GRASS GIS 8.4.1.lnk" "%BATCH%"  "--gui" "%DOCUMENTS%" "Launch GRASS GIS 8.4.1" 1 "%ICON%"

rem run g.mkfontcap outside a GRASS session during
rem an OSGeo4W installation for updating paths to fonts

rem set gisbase
set GISBASE=%OSGEO4W_ROOT%\apps\grass\grass84

rem set path to freetype dll and its dependencies
set FREETYPEBASE=%OSGEO4W_ROOT%\bin;%OSGEO4W_ROOT%\apps\msys\bin;%GISBASE%\lib

rem set dependencies to path
set PATH=%FREETYPEBASE%;%PATH%

rem GISRC must be set
set GISRC=dummy

rem run g.mkfontcap outside a GRASS session
"%GISBASE%\bin\g.mkfontcap.exe" --overwrite

del "%BATCH%.tmpl
