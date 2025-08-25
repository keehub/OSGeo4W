if not defined OSGEO4W_DESKTOP for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Desktop`) do set OSGEO4W_DESKTOP=%%F
for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

@REM TODO kestrel 移除多余快捷方式
@REM if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\SAGA GIS 9.8.1.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\saga_gui.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\saga\saga_gui.exe"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\SAGA GIS 9.8.1.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "\"%OSGEO4W_ROOT%\bin\saga_gui.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\apps\saga\saga_gui.exe"

del %OSGEO4W_ROOT%\saga_gui.ini
