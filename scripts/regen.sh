#!/bin/bash

set -e

export OSGEO4W_REP="C:\ProgramHub\OSGeo4W"
export D=$(cygpath -a "$(dirname "${BASH_SOURCE[0]}")")

source "$D/build-helpers"

if [ -z "$OSGEO4W_REP" ]; then
	echo $0: No repo >&2
	exit 1
fi

regen

(
	cd $OSGEO4W_REP
	diff -u x86_64/setup.ini.prev x86_64/setup.ini || true
)

# TODO kestrel 现将自定义生成的setup.ini与官方setup.osgeo.ini合并
(
	# 定义配置文件路径
	CUSTOM_INI="$OSGEO4W_REP/x86_64/setup.ini"
	OFFICIAL_INI="$OSGEO4W_REP/kestrel/osgeo4w/setup.osgeo.ini"
	MERGED_INI="$OSGEO4W_REP/x86_64/setup.ini.merged"
	BACKUP_INI="$OSGEO4W_REP/x86_64/setup.ini.prev"

	# 检查官方配置文件是否存在
	if [ ! -f "$OFFICIAL_INI" ]; then
		echo "$0: 未找到官方配置 $Official_INI，直接使用自定义setup.INI " >&2
		exit 0
	fi

	# 备份当前生成的setup.ini作为prev
	cp -f "$CUSTOM_INI" "$BACKUP_INI"

	# 使用awk合并配置文件
	awk '
		# 处理自定义配置文件，记录所有包和全局配置
		FILENAME == ARGV[1] {
			if ($0 ~ /^@ /) {  # 包起始标记（如@ package-name）
				current_package = $0
				package_content[current_package] = $0 "\n"
				in_package = 1
				has_package[current_package] = 1
			} else if (in_package) {  # 包内容行
				if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^@ /) {  # 包结束标记（空行或新包）
					in_package = 0
					package_content[current_package] = package_content[current_package] $0 "\n"
				} else {
					package_content[current_package] = package_content[current_package] $0 "\n"
				}
			} else {  # 全局配置行（非包内容）
				if (!global_header_written) {
					global_header = global_header $0 "\n"
				}
			}
			next
		}

		# 处理官方配置文件，补充自定义没有的包
		FILENAME == ARGV[2] {
			if ($0 ~ /^@ /) {  # 包起始标记
				current_official_package = $0
				if (!has_package[current_official_package]) {  # 自定义中没有该包
					in_official_package = 1
					official_package_content = $0 "\n"
				} else {
					in_official_package = 0
				}
			} else if (in_official_package) {  # 收集官方包内容
				if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^@ /) {  # 包结束
					in_official_package = 0
					official_package_content = official_package_content $0 "\n"
					# 保存官方包内容（使用英文变量名）
					supplement_pkgs[++supplement_count] = official_package_content
				} else {
					official_package_content = official_package_content $0 "\n"
				}
			}
			next
		}

		# 输出合并结果
		END {
			# 输出全局配置（来自自定义）
			print global_header

			# 输出自定义包
			for (p in package_content) {
				printf "%s", package_content[p]
			}

			# 输出官方补充的包（使用英文变量名）
			for (i = 1; i <= supplement_count; i++) {
				printf "%s", supplement_pkgs[i]
			}
		}
	' "$CUSTOM_INI" "$OFFICIAL_INI" > "$MERGED_INI"

	# 用合并后的配置替换原setup.ini
	mv -f "$MERGED_INI" "$CUSTOM_INI"
)
