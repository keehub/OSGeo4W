
@REM TODO kestrel 移除多余快捷方式
@REM if not %OSGEO4W_MENU_LINKS%==0 mkdir "%OSGEO4W_STARTMENU%"
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\OSGeo4W Shell.lnk" "%OSGEO4W_ROOT%\OSGeo4W.bat" " " "%OSGEO4W_ROOT%" "OSGeo for Windows command shell" 1 "%OSGEO4W_ROOT%\OSGeo4W.ico"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 mkdir "%OSGEO4W_DESKTOP%"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\OSGeo4W Shell.lnk" "%OSGEO4W_ROOT%\OSGeo4W.bat" " " "%OSGEO4W_ROOT%" "OSGeo for Windows command shell" 1 "%OSGEO4W_ROOT%\OSGeo4W.ico"

@REM  TODO kestrel 删除用户配置文件夹
if exist "%APPDATA%\QGIS" rmdir /s /q "%APPDATA%\QGIS"
if exist "%LOCALAPPDATA%\QGIS" rmdir /s /q "%LOCALAPPDATA%\QGIS"