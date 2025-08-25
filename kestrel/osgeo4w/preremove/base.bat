@REM del "%OSGEO4W_STARTMENU%\OSGeo4W Shell.lnk"
@REM rmdir "%OSGEO4W_STARTMENU%"
@REM del "%OSGEO4W_DESKTOP%\OSGeo4W Shell.lnk"
@REM rmdir "%OSGEO4W_DESKTOP%"

@REM  TODO kestrel 删除快捷链接
set APPNAME=黄陵智慧水务地理信息服务
if exist "%USERPROFILE%\Desktop\%APPNAME%.lnk" del "%USERPROFILE%\Desktop\%APPNAME%.lnk"
if exist "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\%APPNAME%.lnk" del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\%APPNAME%.lnk"

@REM  TODO kestrel 删除用户配置文件夹
if exist "%APPDATA%\QGIS" rmdir /s /q "%APPDATA%\QGIS"
if exist "%LOCALAPPDATA%\QGIS" rmdir /s /q "%LOCALAPPDATA%\QGIS"

@REM  TODO kestrel 删除整个程序文件夹
if exist "%OSGEO4W_ROOT%" rmdir /s /q "%OSGEO4W_ROOT%"