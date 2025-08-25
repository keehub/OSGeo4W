#!/bin/bash

set -e

cert=$PWD/src/setup/osgeo4w/OSGeo_DigiCert_Signing_Cert
# : ${mirror:=https://download.osgeo.org/osgeo4w/v2}
: ${mirror:=file:///C:/ProgramHub/OSGeo4W}

sign=
if [ -r "$cert.p12" -a -r "$cert.pass" ]; then
	[ -z "$CI" ] || echo "::add-mask::$(<$cert.pass)"
	sign="-signwith=$cert.p12 -signpass=$(<$cert.pass)"
fi
# TODO kestrel 遍历脚本参数，如果没有参数则默认使用 qgis-dev
for i in "${@:-qgis-dev}"; do
	o=
	if [ -f "src/$i/qgis/CMakeLists.txt" -a src/$i/osgeo4w/qgis_msibanner.bmp -a src/$i/osgeo4w/qgis_msiinstaller.bmp -a src/$i/osgeo4w/qgis.ico ]; then
		o="-releasename=$(sed -ne 's/^set(RELEASE_NAME "\(.*\)").*$/\1/ip' src/$i/qgis/CMakeLists.txt)"
		o="$o -banner=$PWD/src/$i/osgeo4w/qgis_msibanner.bmp"
		o="$o -background=$PWD/src/$i/osgeo4w/qgis_msiinstaller.bmp"
		o="$o -arpicon=$PWD/src/$i/osgeo4w/qgis.ico"
	fi

	case "$i" in
	*qt6*)
		o="$o -packagename='QGISQT6'"
		;;
	esac

	[ -z "$CI" ] || echo "::group::Creating MSI for $i"

	eval perl scripts/createmsi.pl \
		$sign \
		$o \
		-verbose \
		-shortname="$i" \
		-mirror=$mirror \
		-manufacturer=黄陵智慧水务地理信息服务 \
		$i-full

	[ -z "$CI" ] || echo "::endgroup::"
done
