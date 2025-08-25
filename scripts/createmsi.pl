#!/usr/bin/env perl
# creates a MSI installer from OSGeo4W packages
# note: works also on Linux using wine and wine mono

# Copyright (C) 2020 Jürgen E. Fischer <jef@norbit.de>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

#
# Download OSGeo4W packages
#

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::UUID;
use File::Copy;
use File::Basename;
use Cwd qw/abs_path/;
use Encode qw(decode_utf8 encode);

my $ug = Data::UUID->new;

my $keep = 0;
my $verbose = 0;

my $packagename = "QGIS";
my $releasename;
my $shortname = "qgis";
my $version;
my $binary;
my $root = "http://download.osgeo.org/osgeo4w/v2";
my $ininame = "setup.ini";
my $signwith;
my $signpass;
my $help;
my $manufacturer = "QGIS.org";
my $background;
my $banner;
my $arpicon;

my $BASEDIR = dirname(__FILE__);
$BASEDIR = `cygpath -am '$BASEDIR'`;
chomp $BASEDIR;

my $result = GetOptions(
		"verbose+" => \$verbose,
		"keep" => \$keep,
		"signwith=s" => \$signwith,
		"signpass=s" => \$signpass,
		"releasename=s" => \$releasename,
		"version=s" => \$version,
		"binary=i" => \$binary,
		"packagename=s" => \$packagename,
		"manufacturer=s" => \$manufacturer,
		"shortname=s" => \$shortname,
		"ininame=s" => \$ininame,
		"mirror=s" => \$root,
		"banner=s" => \$banner,
		"background=s" => \$background,
		"arpicon=s" => \$arpicon,
		"help" => \$help
	);

die "certificate not found" if defined $signwith && ! -f $signwith;

# my $codepage = "65001";
# if(defined $releasename) {
# 	my $r = decode_utf8($releasename);
# 	undef $codepage;
# 	for my $c (qw/1252 1250/) {
# 		$ereleasename = eval { encode("windows-$c", $r, Encode::FB_CROAK) };
# 		next unless defined $ereleasename;
# 		$codepage = $c;
# 		last;
# 	}
# 	die "No encoding for releasename $releasename found" unless defined $codepage;
# }
my $ereleasename;
if (defined $releasename) {
    $ereleasename = eval { encode("UTF-8", decode_utf8($releasename), Encode::FB_CROAK) };
}

if(defined $banner) {
	die "banner $banner not found" unless -r $banner;
	$banner = `cygpath -am '$banner'`;
	chomp $banner;
	$banner = '<WixVariable Id="WixUIBannerBmp" Value="' . $banner . '" />';
} else {
	$banner = "";
}

if(defined $background) {
	die "background $background not found" unless -r $background;
	$background = `cygpath -am '$background'`;
	chomp $background;
	$background = '<WixVariable Id="WixUIDialogBmp" Value="' . $background . '" />';
} else {
	$background = "";
}

if(defined $arpicon) {
	die "arpicon $arpicon not found" unless -r $arpicon;
	$arpicon = `cygpath -am '$arpicon'`;
	chomp $arpicon;
	$arpicon = '<Icon Id="icon.ico" SourceFile="' . $arpicon . '" /> <Property Id="ARPPRODUCTICON" Value="icon.ico" />';
} else {
	$arpicon = "";
}

pod2usage(1) if $help;

# my $wgetopt = $verbose ? "" : "-nv";
# 1. 修改wget命令处理部分，增加本地文件支持函数
sub fetch_file {
    my ($source, $dest, $verbose) = @_;
	# file:///C:/ProgramHub/OSGeo4W/x86_64/setup.ini
    if ($source =~ /^file:\/\//) {
        # 处理本地文件
        $source =~ s/^file:\/\/\///;
        # 在Windows上转换路径格式
        $source =~ s/\//\\/g if $^O =~ /cygwin|mswin32/;
        if (-f $source) {
            print "Copying local file: $source to $dest\n" if $verbose;
            copy($source, $dest) or die "Failed to copy $source to $dest: $!";
            return 1;
        } else {
            die "Local file not found: $source";
        }
    } else {
        # 处理网络文件
        my $wgetopt = $verbose ? "" : "-nv";
        my $cmd = "wget $wgetopt -c -O \"$dest\" \"$source\"";
        print "Downloading: $cmd\n" if $verbose;
        system($cmd);
        return $? == 0;
    }
}
mkdir "msi", 0755 unless -d "msi";
mkdir "msi/packages", 0755 unless -d "msi/packages";
chdir "msi/packages";

# 3. 修改Wix工具集下载部分
# unless(-d "wix") {
# 	system "wget $wgetopt -c https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip";
# 	die "download of wix failed" if $?;

# 	mkdir "wix", 0755;
# 	chdir "wix";
# 	system "unzip ../wix311-binaries.zip; chmod a+rx *.dll *.exe";
# 	die "unzip of wix failed" if $?;
# 	chdir "..";
# }
unless(-d "wix") {
    my $wix_url = "https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip";
    unless (fetch_file($wix_url, "wix311-binaries.zip", $verbose)) {
        die "download of wix failed";
    }

    mkdir "wix", 0755;
    chdir "wix";
    system "unzip ../wix311-binaries.zip; chmod a+rx *.dll *.exe";
    die "unzip of wix failed" if $?;
    chdir "..";
}

# 4. 修改wine-mono下载部分
# if($^O ne "cygwin") {
# 	unless(-f "wine-mono-5.1.0-x86.msi") {
# 		system "wget $wgetopt -c https://dl.winehq.org/wine/wine-mono/5.1.0/wine-mono-5.1.0-x86.msi";
# 		die "download of wine-mono failed" if $?;
# 		system "wine msiexec /i wine-mono-5.1.0-x86.msi";
# 		die "install of wine-mono failed" if $?;
# 	}
# }
if($^O ne "cygwin") {
    unless(-f "wine-mono-5.1.0-x86.msi") {
        my $wine_mono_url = "https://dl.winehq.org/wine/wine-mono/5.1.0/wine-mono-5.1.0-x86.msi";
        unless (fetch_file($wine_mono_url, "wine-mono-5.1.0-x86.msi", $verbose)) {
            die "download of wine-mono failed";
        }
        system "wine msiexec /i wine-mono-5.1.0-x86.msi";
        die "install of wine-mono failed" if $?;
    }
}
my %dep;
my %file;
my %lic;
my %version;
my %sdesc;
my %md5;
my $package;

# 2. 修改setup.ini下载部分
# system "wget $wgetopt --no-cache -O setup.ini $root/x86_64/$ininame";
# die "download of setup.ini failed" if $?;
my $setup_ini_url = "$root/x86_64/$ininame";

unless (fetch_file($setup_ini_url, "setup.ini", $verbose)) {
    die "download of setup.ini failed";
}

open F, "setup.ini" || die "setup.ini not found";
while(<F>) {
	my $file;
	my $md5;

	chop;
	if(/^@ (\S+)/) {
		$package = $1;
	} elsif( /^version: (.*)$/ ) {
		$version{$package} = $1 unless exists $version{$package};
	} elsif( /^requires: (.*)$/ ) {
		@{$dep{$package}} = split / /, $1;
	} elsif( ($file,$md5) = /^install:\s+(\S+)\s+.*\s+(\S+)$/) {
		$file{$package} = $file unless exists $file{$package};
		$file =~ s/^.*\///;
		$md5{$file} = $md5 unless exists $md5{$file};
	} elsif( ($file,$md5) = /^license:\s+(\S+)\s+.*\s+(\S+)$/) {
		$lic{$package} = $file unless exists $lic{$package};
		$file =~ s/^.*\///;
		$md5{$file} = $md5 unless exists $md5{$file};
	} elsif( /^sdesc:\s*"(.*)"\s*$/) {
		$sdesc{$package} = $1 unless exists $sdesc{$package};
	}
}
close F;


my %pkgs;

sub getDeps {
	my $pkg = shift;

	my $deponly = $pkg =~ /-$/;
	$pkg =~ s/-$//;

	unless($deponly) {
		return if exists $pkgs{$pkg};
		print " Including package $pkg\n" if $verbose;
		$pkgs{$pkg} = 1;
	} elsif( exists $pkgs{$pkg} ) {
		print " Excluding package $pkg\n" if $verbose;
		delete $pkgs{$pkg};
		return;
	} else {
		print " Including dependencies of package $pkg\n" if $verbose;
	}

	foreach my $p ( @{ $dep{$pkg} } ) {
		getDeps($p);
	}
}

sub getuuid {
	my($file) = shift;
	my $uuid;

	if(-f $file) {
		open F, "$file" or die "cannot open $file: $!";
		$uuid = <F>;
		close F;
	} else {
		$uuid = $ug->to_string($ug->create());
		open F, ">$file" or die "cannot open $file: $!";
		print F $uuid;
		close F;
	}
	return $uuid;
}

unless(@ARGV) {
	print "Defaulting to qgis-full package...\n" if $verbose;
	push @ARGV, "qgis-full";
}

($version) = $version{$ARGV[0]} =~ /^(\d+\.\d+\.\d+)-/ unless defined $version;

die "no version specified" unless defined $version;
die "invalid version $version" unless $version =~ /^\d+\.\d+\.\d+$/;

getDeps($_) for @ARGV;

my @lic;
my @desc;
# 5. 修改包文件下载部分
# foreach my $p ( keys %pkgs ) {
# 	my @f;
# 	unless( exists $file{$p} ) {
# 		print "No file for package $p found.\n" if $verbose;
# 		next;
# 	}
# 	push @f, "$root/$file{$p}";

# 	if( exists $lic{$p} ) {
# 		push @f, "$root/$lic{$p}";
# 		my($l) = $lic{$p} =~ /([^\/]+)$/;
# 		push @lic, $l;
# 		push @desc, $sdesc{$p};
# 	}

# 	for my $f (@f) {
# 		$f =~ s/\/\.\//\//g;

# 		my($file) = $f =~ /([^\/]+)$/;

# 		next if -f $file;

# 		print "Downloading $file [$f]...\n" if $verbose;
# 		system "wget $wgetopt -c $f";
# 		die "download of $f failed" if $? or ! -f $file;

# 		if( exists $md5{$file} ) {
# 			my $md5;
# 			open F, "md5sum '$file'|";
# 			while(<F>) {
# 				if( /^(\S+)\s+\*?(.*)$/ && $2 eq $file ) {
# 					$md5 = $1;
# 				}
# 			}
# 			close F;

# 			die "No md5sum of $p determined [$file]" unless defined $md5;
# 			if( $md5 eq $md5{$file} ) {
# 				print "md5sum of $file verified.\n" if $verbose;
# 			} else {
# 				die "md5sum mismatch for $file [$md5 vs $md5{$file{$p}}]"
# 			}
# 		}
# 		else
# 		{
# 			die "md5sum for $file not found.\n";
# 		}
# 	}
# }
foreach my $p ( keys %pkgs ) {
    my @f;
    unless( exists $file{$p} ) {
        print "No file for package $p found.\n" if $verbose;
        next;
    }
    push @f, "$root/$file{$p}";

    if( exists $lic{$p} ) {
        push @f, "$root/$lic{$p}";
        my($l) = $lic{$p} =~ /([^\/]+)$/;
        push @lic, $l;
        push @desc, $sdesc{$p};
    }

    for my $f (@f) {
        $f =~ s/\/\.\//\//g;

        my($file) = $f =~ /([^\/]+)$/;

        next if -f $file;

        print "Processing $file [$f]...\n" if $verbose;
        
        # 使用统一的文件获取函数，支持网络和本地文件
        unless (fetch_file($f, $file, $verbose)) {
            die "failed to retrieve $f";
        }

        if( exists $md5{$file} ) {
            my $md5;
            open F, "md5sum '$file'|";
            while(<F>) {
                if( /^(\S+)\s+\*?(.*)$/ && $2 eq $file ) {
                    $md5 = $1;
                }
            }
            close F;

            die "No md5sum of $p determined [$file]" unless defined $md5;
            if( $md5 eq $md5{$file} ) {
                print "md5sum of $file verified.\n" if $verbose;
            } else {
                die "md5sum mismatch for $file [$md5 vs $md5{$file}]"
            }
        }
        else
        {
            die "md5sum for $file not found.\n";
        }
    }
}

chdir "..";

#
# Unpack them
# Add addons
#

if( -d "unpacked" ) {
	unless( $keep ) {
		print "Removing unpacked directory\n" if $verbose;
		system "rm -rf unpacked";
		die "removal of unpacked failed" if $?;
	} else {
		print "Keeping unpacked directory\n" if $verbose;
	}
}

if( -f "packages/files.wxs") {
	unless( $keep ) {
		print "Removing files.wxs\n" if $verbose;
		system "rm -f packages/files.wxs";
		die "removal of packages/files failed" if $?;
	} else {
		print "Keeping files.wxs\n" if $verbose;
	}
}

my $taropt = "v" x $verbose;

unless(-d "unpacked" ) {
	mkdir "unpacked", 0755;
	mkdir "unpacked/bin", 0755;
	mkdir "unpacked/etc", 0755;
	mkdir "unpacked/etc/setup", 0755;

	# Create package database
	open O, ">unpacked/etc/setup/installed.db";
	print O "INSTALLED.DB 2\n";

	foreach my $pn ( keys %pkgs ) {
		my $p = $file{$pn};
		unless( defined $p ) {
			print "No package found for $pn\n" if $verbose;
			next;
		}

		$p =~ s#^.*/##;

		unless( -r "packages/$p" ) {
			print "Package $p not found.\n" if $verbose;
			next;
		}

		print O "$pn $p 0\n";

		print "Unpacking $p...\n" if $verbose;
		system "bash -c 'tar $taropt -C unpacked -xjvf packages/$p | gzip -c >unpacked/etc/setup/$pn.lst.gz && [ \${PIPESTATUS[0]} == 0 -a \${PIPESTATUS[1]} == 0 ]'";
		die "unpacking of packages/$p failed" if $?;

		system "sed -i -e 's/bgspawn.exe/elevate.exe/g' unpacked/etc/postinstall/setup.bat" if $pn eq "setup";
	}

	close O;

	if( -d "addons" ) {
		chdir "unpacked";
		print " Including addons...\n" if $verbose;
		system "tar -C ../addons -cf - . | tar $taropt -xf -";
		die "copying of addons failed" if $?;
		chdir "..";
	}
}

unless( defined $binary ) {
	if( -f ".$shortname.$version.binary" ) {
		open P, ".$shortname.$version.binary";
		$binary = <P>;
		close P;
		$binary++;
	} else {
		$binary = 1;
	}
}

#
# Create postinstall.bat
#

open F, ">packages/postinstall.bat";

my $b = "\"%OSGEO4W_ROOT%\\etc\\preremove-conf.bat\"";
my $c = ">>$b";

print F <<EOF;
echo on
set OSGEO4W_ROOT=%~dp0
set OSGEO4W_ROOT=%OSGEO4W_ROOT:~0,-4%
set OSGEO4W_STARTMENU=%~1
set OSGEO4W_DESKTOP=%~2
set OSGEO4W_DESKTOP_LINKS=%~3
if not defined OSGEO4W_DESKTOP_LINKS set OSGEO4W_DESKTOP_LINKS=0
set OSGEO4W_MENU_LINKS=%~4
if not defined OSGEO4W_MENU_LINKS set OSGEO4W_MENU_LINKS=0

for %%i in ("%OSGEO4W_ROOT%") do set OSGEO4W_ROOT=%%~fsi
if "%OSGEO4W_ROOT:~-1%"=="\\" set OSGEO4W_ROOT=%OSGEO4W_ROOT:~0,-1%
if "%OSGEO4W_STARTMENU:~-1%"=="\\" set OSGEO4W_STARTMENU=%OSGEO4W_STARTMENU:~0,-1%
if "%OSGEO4W_DESKTOP:~-1%"=="\\" set OSGEO4W_DESKTOP=%OSGEO4W_DESKTOP:~0,-1%

if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"
if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"

set OSGEO4W_ROOT_MSYS=%OSGEO4W_ROOT:\\=/%
if "%OSGEO4W_ROOT_MSYS:~1,1%"==":" set OSGEO4W_ROOT_MSYS=/%OSGEO4W_ROOT_MSYS:~0,1%/%OSGEO4W_ROOT_MSYS:~3%

if exist $b del $b
echo set OSGEO4W_ROOT=%OSGEO4W_ROOT%$c
echo set OSGEO4W_ROOT_MSYS=%OSGEO4W_ROOT_MSYS%$c
echo set OSGEO4W_STARTMENU=%OSGEO4W_STARTMENU%$c
echo set OSGEO4W_DESKTOP=%OSGEO4W_DESKTOP%$c
echo set OSGEO4W_MENU_LINKS=^%OSGEO4W_MENU_LINKS%$c
echo set OSGEO4W_DESKTOP_LINKS=^%OSGEO4W_DESKTOP_LINKS%$c

\@echo.
\@echo %DATE% %TIME%: Running postinstall
\@echo --------------------------------------------------------------------------------
type $b

PATH %OSGEO4W_ROOT%\\bin;%PATH%
cd /d %OSGEO4W_ROOT%
EOF

# TODO kestrel 复制脚本替换 
my $postinstall_bat_status = system('bash -c "cp /cygdrive/c/ProgramHub/OSGeo4W/kestrel/osgeo4w/postinstall/*.bat /cygdrive/c/ProgramHub/OSGeo4W/msi/unpacked/etc/postinstall/"');
my $preremove_bat_status = system('bash -c "cp /cygdrive/c/ProgramHub/OSGeo4W/kestrel/osgeo4w/preremove/*.bat /cygdrive/c/ProgramHub/OSGeo4W/msi/unpacked/etc/preremove/"');

chdir "unpacked";
for my $p (<etc/postinstall/*.bat>) {
	$p =~ s/\//\\/g;
	my($dir,$file) = $p =~ /^(.+)\\([^\\]+)$/;

	print F <<EOF;
\@echo.
\@echo %DATE% %TIME%: Running postinstall $file...
\@echo --------------------------------------------------------------------------------
%COMSPEC% /c "%OSGEO4W_ROOT%\\$p"
set e=%errorlevel%
ren "%OSGEO4W_ROOT%\\$p" $file.done
\@echo --------------------------------------------------------------------------------
\@echo %DATE% %TIME%: Done postinstall $file [%e%].
\@echo.

EOF
}
chdir "..";

print F <<EOF;
exit /b 0
EOF

close F;

open F, ">packages/preremove.bat";
print F <<EOF;
\@echo on
\@echo %DATE% %TIME%: Running preremove...
\@echo --------------------------------------------------------------------------------
call "%~dp0\\preremove-conf.bat"
\@echo OSGEO4W_ROOT=%OSGEO4W_ROOT%
\@echo OSGEO4W_ROOT_MSYS=%OSGEO4W_ROOT_MSYS%
\@echo OSGEO4W_STARTMENU=%OSGEO4W_STARTMENU%
\@echo OSGEO4W_DESKTOP=%OSGEO4W_DESKTOP%
call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"
cd /d \"%OSGEO4W_ROOT%\"
EOF

chdir "unpacked";
for my $p (<etc/preremove/*.bat>) {
	$p =~ s/\//\\/g;
	my($dir,$file) = $p =~ /^(.+)\\([^\\]+)$/;

	print F <<EOF;
\@echo Running preremove $file...
\@echo %DATE% %TIME%: Running preremove $file...
\@echo --------------------------------------------------------------------------------
%COMSPEC% /c $p
set e=%errorlevel%
\@echo --------------------------------------------------------------------------------
\@echo %DATE% %TIME%: Done preremove $file [%e%].

EOF
}

chdir "..";

print F <<EOF;
rmdir /s /q "%OSGEO4W_STARTMENU%"
rmdir /s /q "%OSGEO4W_DESKTOP%"
del "%OSGEO4W_ROOT%\\etc\\postinstall\\*.done"
del "%OSGEO4W_ROOT%\\etc\\postinstall.bat"
del "%OSGEO4W_ROOT%\\etc\\preremove.bat"
del "%OSGEO4W_ROOT%\\etc\\preremove-conf.bat"
del "%OSGEO4W_ROOT%\\var\\log\\postinstall.log"
echo --------------------------------------------------------------------------------
echo %DATE% %TIME%: Done preremove
EOF

close F;

print "Creating license file\n" if $verbose;

my $lic;
for my $l ( ( "unpacked/apps/$shortname/doc/LICENSE", "../COPYING" ) ) {
	next unless -f $l;
	$lic = $l;
	last;
}

warn "no QGIS license found" unless defined $lic;
# TODO kestrel 修改创建许可证文件部分的代码，替换为指定的许可证内容
# open RTF, "| enscript -w rtf -o - | sed -e 's/^License overview:/\\\\fs18&/' >packages/license.temp";
# my $license = "packages/license.txt";
# open O, ">$license";

# sub out {
# 	my $m = shift;
# 	print RTF $m;
# 	print O $m;
# }

# my $i = 0;
# if( @lic ) {
# 	out("License overview:\n");
# 	out("1. QGIS\n") if defined $lic;
# 	$i = defined $lic ? 1 : 0;
# 	for my $l ( @desc ) {
# 		out(++$i . ". $l\n");
# 	}
# 	$i = 0;
# 	out("\n\n----------\n\n");
# 	out(++$i . ". License of 'QGIS'\n\n") if defined $lic;
# }

# if(defined $lic) {
# 	print " Including QGIS license $lic\n" if $verbose;
# 	open I, $lic;
# 	while(<I>) {
# 		s/\s*$/\n/;
# 		out($_);
# 	}
# 	close I;
# }

# for my $l (@lic) {
# 	print " Including license $l\n" if $verbose;

# 	open I, "packages/$l" or die "License $l not found.";
# 	out("\n\n----------\n\n" . ++$i . ". License of '" . shift(@desc) . "'\n\n");
# 	while(<I>) {
# 		s/\s*$/\n/;
# 		out($_);
# 	}
# 	close I;
# }

# close RTF;
# close O;

open RTF, "| enscript -w rtf -o - | sed -e 's/^软件许可证协议:/\\\\fs18&/' >packages/license.temp";
my $license = "packages/license.txt";
open O, ">$license";
sub out {
    my $m = shift;
    print RTF $m;
    print O $m;
}

out("“$manufacturer的软件许可证协议”（以下简称 “本协议”）由软件授权方（以下简称 “授权方”）与软件使用方（以下简称 “使用方”）签订，旨在规范双方在软件使用过程中的权利和义务。\n\n");
out("一、定义\n");
out("“软件”：指授权方开发并授权使用方使用的特定计算机程序及其相关文档。\n");
out("“使用方”：指获得软件使用授权的个人、企业或其他组织。\n");
out("“授权方”：指拥有软件版权并授予使用方使用许可的一方。\n\n");
out("二、授权范围\n");
out("授权方授予使用方非独占性的、不可转让的使用许可，允许使用方在授权范围内使用本软件。\n");
out("使用方仅有权在其内部业务运营中使用本软件，不得将软件用于任何第三方，包括但不限于出租、出借、转售或提供软件服务。\n\n");
out("三、使用限制\n");
out("使用方不得对软件进行反向工程、反编译、反汇编或以其他方式试图获取软件的源代码，除非法律明确允许。\n");
out("使用方不得修改、改编软件，不得创建软件的衍生作品，不得删除或更改软件中的任何版权声明或其他所有权标识。\n");
out("使用方应遵守软件使用过程中的相关规定，不得利用软件进行任何违法违规活动。\n\n");
out("四、知识产权\n");
out("软件的所有知识产权，包括但不限于版权、专利、商标等，均归授权方所有。\n");
out("使用方在使用软件过程中所产生的任何成果，其知识产权归属由双方另行协商确定或遵循相关法律法规。\n\n");
out("五、期限与终止\n");
out("本协议自双方签署之日起生效，有效期为 [X] 年。除非提前终止，协议期满后可根据双方协商进行续约。\n");
out("若使用方违反本协议的任何条款，授权方有权立即终止本协议，并要求使用方停止使用软件、销毁软件的所有副本。\n\n");
out("六、责任限制\n");
out("授权方对软件的使用不提供任何明示或暗示的保证，包括但不限于适销性、特定用途适用性等保证。\n");
out("在任何情况下，授权方对因使用方使用软件所产生的任何直接、间接、偶然、特殊或后果性损失不承担责任，除非该损失是由授权方的故意或重大过失造成。\n\n");
out("七、法律适用与争议解决\n");
out("本协议的签订、履行、解释及争议解决均适用 [具体法律管辖区] 法律。\n");
out("双方在本协议履行过程中如发生争议，应首先通过友好协商解决；协商不成的，任何一方均可向有管辖权的人民法院提起诉讼。\n");

close RTF;
close O;

system "cp $license unpacked/apps/$shortname/doc/LICENSE" if -f "unpacked/apps/$shortname/doc/LICENSE";
system "cp packages/license.temp packages/license.rtf";

#  kestrel 安装包重命名 
# my $installer = "$packagename-OSGeo4W-$version-$binary";
my $datetime = strftime("%Y%m%d-%H%M", localtime);
my $installer = "$manufacturer-$version($datetime)";
my $run = $^O eq "cygwin" ? "" : "wine";

my $productuuid     = getuuid(".$shortname.$version.product");
my $upgradeuuid     = getuuid(".$shortname.$version.upgrade");
my $postinstalluuid = getuuid(".$shortname.$version.postinstall");
my $preremoveuuid   = getuuid(".$shortname.$version.preremove");
my $linkfolders     = getuuid(".$shortname.$version.linkfolders");
my $varloguuid      = getuuid(".$shortname.$version.varlog");

my $fn = 0;
unless($keep && -f "packages/files1.wxs") {
	print "Harvesting files...\n" if $verbose;

	# Harvest ourselves - candle/light doesn't cope well with huge wxses (light doesn't handle symlinks either, so also resolve those)
	# system "$run packages/wix/heat.exe dir unpacked -nologo -var env.UNPACKEDDIR -sw HEAT5150 -cg INSTALLDIR -dr INSTALLDIR -gg -sfrag -srd -template fragment -out packages\\\\files.wxs";
	# die "harvesting failed" if $?;

	my $f;
	my $fi = 0;
	my $indent = 3;
	my @lelements;   # current <Directory> path
	my @components;  # collect components for <ComponentGroup>

	sub wclose {
		my $f = shift;

		while(@lelements) {
			my $item = pop @lelements;
			printf $f "%*s</Directory> <!-- %s -->\n", --$indent, " ", $item;
		}

		print $f <<EOF;
  </DirectoryRef>
 </Fragment>
 <Fragment>
   <ComponentGroup Id="INSTALLDIR$fn">
EOF

		while(@components) {
			my $c = shift @components;
			print $f <<EOF
   <ComponentRef Id="$c" />
EOF
		}

		print $f <<EOF;
  </ComponentGroup> <!-- INSTALLDIR$fn -->
 </Fragment>
</Wix>
EOF

		close $f if defined $f;

	}

	chdir "unpacked";

	open F, "find . -print|";
	while(<F>) {
		#	print;
		if($fi++ % 5000 == 0) {
			wclose($f) if defined $f;
			open $f, ">../packages/files" . ++$fn . ".wxs";

			print $f <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
 <Fragment>
  <DirectoryRef Id="INSTALLDIR">
EOF
		}

		s/^\.\///;
		chomp;

		my @elements = split /\//;

		pop @elements unless -d;

		my $i;
		for($i = 0; $i < @elements && $i < @lelements && $elements[$i] eq $lelements[$i]; $i++ ) {
		}

		while(@lelements > $i) {
			my $item = pop @lelements;
			printf $f "%*s</Directory> <!-- %s -->\n", --$indent, " ", $item;
		}

		while(@elements > @lelements) {
			my $item = $elements[$i++];
			my $did = "dir" .  $ug->to_string($ug->create());
			$did =~ s/-//g;

			printf $f "%*s<Directory Id=\"%s\" Name=\"%s\">\n",
				$indent++, " ", $did, $item;
			push @lelements, $item;
		}

		next if -d $_;

		if(-l $_) {
                	my $d = readlink($_);
			my $p = $_;
			$p =~ s#/[^/]+$#/$d#;
                	unlink $_ or die "Cannot unlink $_: $!";
                	copy($p,$_) or die "Copy $d to $_ failed: $!";
			print " Replacing symlink $_\n" if $verbose;
        	}

		s/\//\\/g;

		my $c = "cmp" . $ug->to_string($ug->create());
		$c =~ s/-//g;
		push @components, $c;

		my $fid = "fil" . $ug->to_string($ug->create());
		$fid =~ s/-//g;

		printf $f "%*s<Component Id=\"%s\" Guid=\"{%s}\">\n%*s<File Id=\"%s\" KeyPath=\"yes\" Source=\"\$(env.UNPACKEDDIR)\\%s\" />\n%*s</Component>\n",
			$indent, " ", $c, $ug->to_string($ug->create()),
			$indent+1, " ", $fid, $_,
			$indent, " ";
	}

	wclose($f) if defined $f;

	chdir "..";
} else {
	$fn = 1;
	while(-f "packages/files$fn.wxs") {
		$fn++;
	}
	$fn--;
}


# WixUIBannerBmp: Top banner							493 × 58
# WixUIDialogBmp: Background bitmap used on the welcome and completion dialogs	493 × 312

# TODO kestrel 安装页面显示产品文本 
# my $productname = "$packagename $version";
# $productname .= " $ereleasename" if defined $ereleasename;
my $productname = "$manufacturer $version";


# TODO kestrel 安装语言的设置 
# open F, ">packages/lang.wxl";
# print F <<EOF;
# <?xml version="1.0" encoding="windows-$codepage"?>
# <WixLocalization Culture="en-us" Codepage="$codepage" xmlns="http://schemas.microsoft.com/wix/2006/localization">
# </WixLocalization>
# EOF
# close F;

open F, ">packages/lang.wxl";
print F <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<WixLocalization Culture="zh-CN" Codepage="936" xmlns="http://schemas.microsoft.com/wix/2006/localization">
    <String Id="SetupWindowTitle">$manufacturer 安装程序</String>
	<String Id="WelcomeDlgTitle">欢迎使用 “$manufacturer” 安装向导</String>
    <String Id="WelcomeDlgDescription">安装向导将在您的计算机上安装 “$manufacturer”。点击“下一步”继续，或点击“取消”退出安装向导。</String>
    </WixLocalization>
EOF
close F;

open F, ">packages/installer.wxs";
print F <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product 
     Id='$productuuid'
	 Name="$productname"
     UpgradeCode="$upgradeuuid"
     Manufacturer="$manufacturer 软件科技有限公司"
     Language="2052" Codepage="936" Version="$version">
    <Package Id="*" Keywords="Installer" 
	  Description="$productname 安装程序"
      Comments="$manufacturer 说明信息"
      Manufacturer="$manufacturer 软件科技有限公司"
      Compressed="yes"
      SummaryCodepage="936"
      InstallerVersion="200"
      InstallScope="perMachine" />

    <Media Id="1" EmbedCab="yes" CompressionLevel="high" Cabinet="application.cab" />
    <Property Id="WIXUI_INSTALLDIR" Value="INSTALLDIR" />
    <Property Id="INSTALLDESKTOPSHORTCUTS" Value="1" />
    <Property Id="INSTALLMENUSHORTCUTS" Value="1" />

    <UIRef Id="QGISUI_InstallDir" />
    <UIRef Id="WixUI_ErrorProgressText" />

    <WixVariable Id="WixUILicenseRtf" Value="license.rtf" />
    $banner
    $background
    $arpicon

    <Directory Id="TARGETDIR" Name="SourceDir">
		<Directory Id="ProgramFiles64Folder">
			<Directory Id="INSTALLDIR" Name="$manufacturer">
			<Directory Id="var" Name="var">
				<Directory Id="varlog" Name="log">
			</Directory>
		</Directory>
		<Directory Id="ETC" Name="etc">
				<Component Id="postinstall.bat" Guid="$postinstalluuid">
				<File Id="postinstall.bat" Name="postinstall.bat" Source="postinstall.bat" />
				</Component>
				<Component Id="preremove.bat" Guid="$preremoveuuid">
				<File Id="preremove.bat" Name="preremove.bat" Source="preremove.bat" />
				</Component>
		</Directory>
        </Directory>
		<Directory Id="ProgramMenuFolder">
			<!-- TODO kestrel 桌面和开始创建文件夹，修改开始菜单文件夹配置 -->
          	<!-- <Directory Id="ApplicationProgramMenuFolder" Name="$packagename $version" /> -->
        </Directory>
		<Directory Id="DesktopFolder">
			<!-- TODO kestrel 桌面和开始创建文件夹，修改桌面文件夹配置 -->
			<!-- <Directory Id="ApplicationDesktopFolder" Name="$packagename $version" /> -->
		</Directory>
      </Directory>
    </Directory>

    <DirectoryRef Id="varlog">
      <Component Id="varlog" Guid="$varloguuid" KeyPath="yes">
        <CreateFolder />
      </Component>
    </DirectoryRef>

    <Feature Id="$packagename" Title="$productname" Level="1">
      <ComponentRef Id="postinstall.bat" />
      <ComponentRef Id="varlog" />
EOF

for(my $i=1; $i <= $fn; $i++) {
	print F "      <ComponentGroupRef Id=\"INSTALLDIR$i\" />\n";
}

print F <<EOF;
      <ComponentRef Id="preremove.bat" />
    </Feature>
	<!-- TODO kestrel 桌面和开始创建文件夹，同步修改引用位置 -->
    <!-- <SetProperty Id="postinstall" Value="&quot;[#postinstall.bat]&quot; &quot;[ApplicationProgramMenuFolder]&quot; &quot;[ApplicationDesktopFolder]&quot; &quot;[INSTALLDESKTOPSHORTCUTS]&quot; &quot;[INSTALLMENUSHORTCUTS]&quot; &gt;&quot;[varlog]\\postinstall.log&quot; 2&gt;&amp;1" Before="postinstall" Sequence='execute' /> -->
	<SetProperty Id="postinstall" Value="&quot;[#postinstall.bat]&quot; &quot;[ProgramMenuFolder]&quot; &quot;[DesktopFolder]&quot; &quot;[INSTALLDESKTOPSHORTCUTS]&quot; &quot;[INSTALLMENUSHORTCUTS]&quot; &gt;&quot;[varlog]\\postinstall.log&quot; 2&gt;&amp;1" Before="postinstall" Sequence='execute' />
	
	<!-- <SetProperty Id="postinstall" Value=""[#postinstall.bat]" "[ApplicationProgramMenuFolder]" "[ApplicationDesktopFolder]" "[INSTALLDESKTOPSHORTCUTS]" "[INSTALLMENUSHORTCUTS]" >"[varlog]\\postinstall.log" 2>&1" Before="postinstall" Sequence='execute' /> -->
	<!-- <SetProperty Id="postinstall" Value=""[#postinstall.bat]" "[ProgramMenuFolder]" "[DesktopFolder]" "[INSTALLDESKTOPSHORTCUTS]" "[INSTALLMENUSHORTCUTS]" >"[varlog]\\postinstall.log" 2>&1" Before="postinstall" Sequence='execute' /> -->
	
	<CustomAction Id="postinstall" BinaryKey="WixCA" DllEntry="WixQuietExec64" Execute="deferred" Return="ignore" Impersonate="no" />

    <SetProperty Id="preremove" Value="&quot;[#preremove.bat]&quot; &gt;&quot;[TempFolder]\\$installer-preremove.log&quot; 2&gt;&amp;1" Before="preremove" Sequence='execute' />
    <CustomAction Id="preremove" BinaryKey="WixCA" DllEntry="WixQuietExec64" Execute="deferred" Return="ignore" Impersonate="no" />

    <InstallExecuteSequence>
      <Custom Action="postinstall" After="InstallFiles">(NOT Installed) AND (NOT REMOVE)</Custom>
      <Custom Action="preremove" After="InstallInitialize">(NOT UPGRADINGPRODUCTCODE) AND (REMOVE="ALL")</Custom>
    </InstallExecuteSequence>
  </Product>
</Wix>
EOF
close F;

chdir "packages";

$ENV{'UNPACKEDDIR'} = "..\\unpacked";

my @wxs;

push @wxs, "installer.wxs";
push @wxs, "$BASEDIR/QGISInstallDirDlg.wxs";
push @wxs, "$BASEDIR/QGISUI_InstallDir.wxs";
push @wxs, "files$_.wxs" foreach 1..$fn;

my @wixobj;
foreach (@wxs) {
	system "$run ./wix/candle.exe -nologo -arch x64 $_";
	die "candle failed" if $?;
	s/\.wxs$/.wixobj/;
	s#^.*/##;
	push @wixobj, $_;
}

print "Running light...\n" if $verbose;

# ICE09, ICE32, ICE61 produce:
# light.exe : error LGHT0217 : Error executing ICE action 'ICExx'. The most common cause of this kind of ICE failure is an incorrectly registered scripting engine. See http://wixtoolset.org/documentation/error217/ for
# details and how to solve this problem. The following string format was not expected by the external UI message logger: "The installer has encountered an unexpected error installing this package. This may indicate a
# problem with this package. The error code is 2738. ".
#
# ICE61 produces following warning for font files:
# warning LGHT1076 : ICE60: The file filXXX is not a Font, and its version is not a companion file reference. It should have a language specified in the Language column.
#
# ICE64: complains about the desktop and start menu folder
# TODO kestrel WiX Toolset 的light.exe工具，设置中文语言等
# my $cmd = "$run ./wix/light.exe -nologo -ext WixUIExtension -ext WixUtilExtension -loc lang.wxl -out $installer.msi -sice:ICE09 -sice:ICE32 -sice:ICE60 -sice:ICE61 -sice:ICE64 -b ../unpacked " . join(" ", @wixobj);
my $cmd = "$run ./wix/light.exe -v -ext WixUIExtension -ext WixUtilExtension -cultures:zh-CN -loc lang.wxl -out $installer.msi -sice:ICE09 -sice:ICE32 -sice:ICE60 -sice:ICE61 -sice:ICE64 -b ../unpacked " . join(" ", @wixobj);
print "EXEC: $cmd\n" if $verbose;
system $cmd;
die "light failed" if $?;

sub sign {
	my $base = shift;

	my $name = "$packagename $version";
	$name .= " '$releasename'" if defined $releasename;

	# for some unclear reason as of 2024-02-24 this requires
	# now requires osslsigncode 2.7 and the verification
	# using ossslsigncode fails eventhough the msi is apparently
	# fine (no complaints when installing)
	my $cmd = "osslsigncode sign";
#	$cmd .= " -nolegacy";
	$cmd .= " -pkcs12 \"\$(cygpath -aw '$signwith')\"";
	$cmd .= " -pass \"$signpass\"" if defined $signpass;
	$cmd .= " -n \"$name\"";
	$cmd .= " -h sha256";
	$cmd .= " -i \"https://qgis.org\"";
	$cmd .= " -t \"http://timestamp.digicert.com\"";
	$cmd .= " -in \"$base.msi\"";
	$cmd .= " \"$base-signed.msi\"";
	system $cmd;
	die "signing failed [$cmd]" if $?;

#	$cmd = "osslsigncode verify \"$base-signed.msi\"";
#	system $cmd;
#	die "verification failed [$cmd]" if $?;

	rename("$base-signed.msi", "$base.msi") or die "rename failed: $!";
}

sign "$installer" if $signwith;

open P, ">../.$shortname.$version.binary";
print P $binary;
close P;

system "sha256sum $installer.msi >$installer.sha256sum";

__END__

=head1 NAME

createmsi.pl - create MSI package from OSGeo4W packages

=head1 SYNOPSIS

createmsi.pl [options] [packages...]

  Options:
    -verbose		increase verbosity
    -releasename=name	name of release (optional)
    -banner=img		name of the top banner (493×58)
    -background=img	background bitmap used on the welcome and completion dialogs (493×312)
    -keep		don't start with a fresh unpacked directory
    -signwith=cert.p12	optionally sign package with certificate (requires osslsigncode)
    -signpass=password	password of certificate
    -version=m.m.p	package version
    -binary=b		binary version of package
    -ininame=filename	name of the setup.ini (defaults to setup.ini)
    -packagename=s	name of package (defaults to 'QGIS')
    -manufacturer=s     name of manufacturer (defaults to 'QGIS.org')
    -shortname=s	shortname used for batch file (defaults to 'qgis')
    -mirror=s		default mirror (defaults to 'http://download.osgeo.org/osgeo4w')
    -help		this help

  If no packages are given 'qgis-full' and it's dependencies will be retrieved
  and packaged.

  Packages with a appended '-' are excluded, but their dependencies are included.
=cut
