
cd C:\ProgramHub\OSGeo4W

bootstrap.cmd qgis-dev

# 第一步：需要添加环境变量
1. window 设置环境变量 C:\Windows\System32\downlevel
2. 文件配置系统变量 .buildenv

# 第二步： 两种包源的加载方式，首先从网络上加载，再从本地加载
1. 官方的setup.ini 替换  kestrel\osgeo4w\setup.osgeo.ini 
2. ${mirror:=https://download.osgeo.org/osgeo4w/v2} ，${mirror:=file:///C:/ProgramHub/OSGeo4W}





