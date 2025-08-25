set http_proxy="http://127.0.0.1:10809"
set https_proxy="http://127.0.0.1:10809"

if exist tmp rmdir /s /q tmp
if not exist scripts mkdir scripts

if defined CI echo ::group::Installing cygwin
if not exist scripts/setup-x86_64.exe curl --output scripts/setup-x86_64.exe https://cygwin.com/setup-x86_64.exe
@REM scripts\setup-x86_64.exe ^
@REM 	-qnNdOW ^
@REM 	-R %CD%/cygwin ^
@REM 	-s http://cygwin.mirror.constant.com ^
@REM 	-l %TEMP%/package-cache ^
@REM 	-P "bison,flex,poppler,doxygen,git,unzip,tar,diffutils,patch,curl,wget,flip,p7zip,make,osslsigncode,mingw64-x86_64-gcc-core,catdoc,enscript,mingw64-x86_64-binutils,perl-Data-UUID,ruby=2.6.4-1,perl-YAML-Tiny"
if defined CI echo ::endgroup::

copy bootstrap.sh cygwin\tmp
cygwin\bin\bash /tmp/bootstrap.sh %*
