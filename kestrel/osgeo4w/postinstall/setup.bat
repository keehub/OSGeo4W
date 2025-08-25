for /F "tokens=* USEBACKQ" %%F IN (`getspecialfolder Documents`) do set DOCUMENTS=%%F

@REM TODO kestrel 移除多余快捷方式
@REM if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
@REM if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\Setup.lnk" "%OSGEO4W_ROOT%\bin\elevate.exe" "\"%OSGEO4W_ROOT%\bin\setup.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\osgeo4w.ico"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"
@REM if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\OSGeo4W Setup.lnk" "%OSGEO4W_ROOT%\bin\elevate.exe" "\"%OSGEO4W_ROOT%\bin\setup.bat\"" "%DOCUMENTS%" "" 1 "%OSGEO4W_ROOT%\osgeo4w.ico"

textreplace -std -t bin\setup.bat
