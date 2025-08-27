@echo off
REM 删除QGIS缓存目录
IF EXIST "%APPDATA%\QGIS" RMDIR /s /q "%APPDATA%\QGIS"
IF EXIST "%LOCALAPPDATA%\QGIS" RMDIR /s /q "%LOCALAPPDATA%\QGIS"

REM 设置OSGEO4W基础路径
SET OSGEO4W_PATH=C:\ProgramHub\OSGeo4W\src\qgis-dev\osgeo4w
SET PATH=%WINDIR%;%WINDIR%\system32;%WINDIR%\system32\WBem;%OSGEO4W_PATH%\osgeo4w\bin;%OSGEO4W_PATH%\osgeo4w\bin
SET PATH=%PATH%;%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\lib;%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\bin
SET PATH=%PATH%;%OSGEO4W_PATH%\osgeo4w\apps\Python312\Scripts;%OSGEO4W_PATH%\osgeo4w\apps\qt5\bin;%OSGEO4W_PATH%\osgeo4w\apps\gdal-dev\bin;
SET PYTHONPATH=%OSGEO4W_PATH%\osgeo4w\osgeo4w\apps\Python312;%OSGEO4W_PATH%\osgeo4w\osgeo4w\apps\Python312\Lib\site-packages;%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84\etc\python;
SET PYTHONHOME=%OSGEO4W_PATH%\osgeo4w\apps\Python312

REM 批处理文件及组件环境变量
SET GS_LIB=%OSGEO4W_PATH%\osgeo4w\apps\gs\lib
SET PROJ_DATA=%OSGEO4W_PATH%\osgeo4w\share\proj
SET OPENSSL_ENGINES=%OSGEO4W_PATH%\osgeo4w\lib\engines-3
SET PDAL_DRIVER_PATH=%OSGEO4W_PATH%\osgeo4w\apps\pdal\plugins
SET QT_PLUGIN_PATH=%OSGEO4W_PATH%\osgeo4w\apps\Qt5\plugins
SET SSL_CERT_DIR=%OSGEO4W_PATH%\osgeo4w\apps\openssl\certs
SET SSL_CERT_FILE=%OSGEO4W_PATH%\osgeo4w\bin\curl-ca-bundle.crt
SET O4W_QT_PREFIX=%OSGEO4W_PATH%\osgeo4w\apps/Qt5
SET O4W_QT_DOC=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/doc
SET O4W_QT_BINARIES=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/bin
SET O4W_QT_LIBRARIES=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/lib
SET O4W_QT_PLUGINS=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/plugins
SET O4W_QT_HEADERS=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/include
SET O4W_QT_TRANSLATIONS=%OSGEO4W_PATH%\osgeo4w\apps/Qt5/translations

REM GRASS环境变量
SET GISBASE=%OSGEO4W_PATH%\osgeo4w\apps\grass\grass84
SET GRASS_PROJSHARE=%OSGEO4W_PATH%\osgeo4w\share\proj

REM GDAL环境变量
SET VSI_CACHE=TRUE
SET VSI_CACHE_SIZE=1000000
SET GDAL_FILENAME_IS_UTF8=YES
SET GDAL_DATA=%OSGEO4W_PATH%\osgeo4w\apps\gdal-dev\share\gdal
SET GDAL_DRIVER_PATH=%OSGEO4W_PATH%\osgeo4w\apps\gdal-dev\lib\gdalplugins

REM 启动QGIS
START "QGIS" /B "%OSGEO4W_PATH%/build/output/bin/qgis.exe"
