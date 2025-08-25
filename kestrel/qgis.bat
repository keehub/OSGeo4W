@echo off
set OSGEO4W_PATH=C:\ProgramHub\OSGeo4W\src\qgis-dev\osgeo4w
call "%OSGEO4W_PATH%\osgeo4w\bin\o4w_env.bat"
call "%OSGEO4W_PATH%\osgeo4w\bin\gdal-dev-env.bat"

if not exist "%OSGEO4W_PATH%\install\apps\qgis-dev\bin\qgisgrass8.dll" goto nograss
if not exist "%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\etc\env.bat" goto nograss

set savedpath=%PATH%
call "%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\etc\env.bat"
path %OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\lib;%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\bin;%savedpath%
:nograss
@echo off

path %OSGEO4W_PATH%\install\apps\qgis-dev\bin;%PATH%
set QGIS_PREFIX_PATH=%OSGEO4W_PATH:\=/%/install/apps/qgis-dev
set GDAL_FILENAME_IS_UTF8=YES
set VSI_CACHE=TRUE
set VSI_CACHE_SIZE=1000000
set QT_PLUGIN_PATH=%OSGEO4W_PATH%\install\apps\qgis-dev\plugins;%OSGEO4W_PATH%\osgeo4w\apps\Qt5\plugins
set PYTHONPATH=%OSGEO4W_PATH%\osgeo4w\apps\Python312;%PYTHONPATH%

start "QGIS" /B "%OSGEO4W_PATH%\install\apps\qgis-dev\bin\qgis.exe" %*