#!/usr/bin/env bang run

# MediaArea-Utils/upgrade_version/UpgradeVersion.sh
# Upgrade the version number of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

# This script requires: bang.sh, wget, zip and p7zip

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h

    b.opt.add_opt --zenlib "ZenLib version"
    b.opt.add_alias --zenlib -zl

    b.opt.add_opt --mediainfolib "MediaInfoLib version"
    b.opt.add_alias --mediainfolib -mil

    b.opt.add_opt --mediaconch "MediaConch version"
    b.opt.add_alias --mediaconch -mc

    b.opt.add_opt --date "Release date"
    b.opt.add_alias --date -d

    # Mandatory arguments
    b.opt.required_args --zenlib --mediainfolib --mediaconch --date
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function makeWindows () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Windows files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/MediaConch_GUI_${mc}_Windows.exe"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Windows_i386.zip"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Windows_x64.zip"

    echo "Create Windows package"
    cp License*.html tmp/
    zip -q -j exec01-$date.zip tmp/*

    rm -rf tmp
}

function makeMacOS () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Mac OS files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/MediaConch_GUI_${mc}_Mac.dmg"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Mac.dmg"

    echo "Create Mac OS package"
    cp License*.html tmp/
    zip -q -j exec05-$date.zip tmp/*

    rm -rf tmp
}


function makeUbuntu () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Ubuntu files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0v5_${mil}-1_i386.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0v5_${zl}-1_i386.xUbuntu_15.10.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0v5_${mil}-1_amd64.xUbuntu_15.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0v5_${zl}-1_amd64.xUbuntu_15.10.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_15.04.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_15.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_15.04.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_14.10.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_14.10.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_14.10.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_14.04.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_14.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_14.04.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_12.04.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_12.04.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_12.04.deb"

    echo "Create Ubuntu package"
    cp License*.html tmp/
    zip -q -j exec09-$date.zip tmp/*

    rm -rf tmp
}

function makeFedora () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Fedora files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_23.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_23.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_23.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_22.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_22.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_22.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_21.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_21.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_21.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_20.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_20.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_20.rpm"

    echo "Create Fedora package"
    cp License*.html tmp/
    zip -q -j exec13-$date.zip tmp/*

    rm -rf tmp
}

function makeDebian () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Debian files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.Debian_8.0.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.Debian_8.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.Debian_8.0.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.Debian_7.0.deb"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.Debian_7.0.deb"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.Debian_7.0.deb"

    echo "Create Debian package"
    cp License*.html tmp/
    zip -q -j exec17-$date.zip tmp/*

    rm -rf tmp
}

function makeSuse () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Suse files"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Leap_42.1.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_Factory.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Factory.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Factory.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_Tumbleweed.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Tumbleweed.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_13.2.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_13.2.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_13.2.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_13.1.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_13.1.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_13.1.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_11.4.rpm"

    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_11.4.rpm"
    wget -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_11.4.rpm"

    echo "Create Suse package"
    cp License*.html tmp/
    zip -q -j exec21-$date.zip tmp/*

    rm -rf tmp
}


function makeSources () {
    if b.path.dir? tmp; then
        rm -f tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Sources files"
    wget -q -P tmp "https://mediaarea.net/download/source/mediaconch/${mc}/mediaconch_${mc}_AllInclusive.7z"

    echo "Create Sources package"
    cd tmp
    7za x mediaconch_${mc}_AllInclusive.7z

    # Copy license files
    cp ../License*.html mediaconch_AllInclusive/
    cp ../License.*.html mediaconch_AllInclusive/MediaInfoLib
    cp ../License.*.html mediaconch_AllInclusive/ZenLib

    # Remove zlib directory
    rm -rf mediaconch_AllInclusive/zlib

    # Replace "BSD" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a BSD-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a BSD-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under BSD-2-Clause license conditions" | xargs -0 sed -i "s/This program is freeware under BSD-2-Clause license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    # Replace "zlib" by "GPL v3+ and MPL v2+" in file headers
    grep -rlZ "Use of this source code is governed by a zlib-style license that" | xargs -0 sed -i "s/Use of this source code is governed by a zlib-style license that/Use of this source code is governed by a GPL v3+ and MPL v2+ license that/g"
    grep -rlZ "This program is freeware under zlib license conditions" | xargs -0 sed -i "s/This program is freeware under zlib license conditions/This program is freeware under GPL v3+ and MPL v2+ license conditions/g"

    zip -q -r ../src01-$date.zip mediaconch_AllInclusive
    cd ../
    cp src01-$date.zip src05-$date.zip
    cp src01-$date.zip src09-$date.zip
    cp src01-$date.zip src13-$date.zip
    cp src01-$date.zip src17-$date.zip
    cp src01-$date.zip src21-$date.zip

    rm -rf tmp
}

function getLicensesFiles () {
    echo "Download licenses files"
    if ! b.path.file? "License.html"; then
        wget -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.html"
    fi

    if ! b.path.file? "License.GPLv3.html"; then
        wget -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.GPLv3.html"
    fi

    if ! b.path.file? "License.MPLv2.html"; then
        wget -q "https://raw.githubusercontent.com/MediaArea/MediaConch_SourceCode/master/License.MPLv2.html"
    fi

}

function run () {
    load_options
    b.opt.init "$@"

    # Display help
    if b.opt.has_flag? --help; then
        b.opt.show_usage
        exit
    fi

    if b.opt.check_required_args; then
        zl=$(sanitize_arg $(b.opt.get_opt --zenlib))
        mil=$(sanitize_arg $(b.opt.get_opt --mediainfolib))
        mc=$(sanitize_arg $(b.opt.get_opt --mediaconch))
        date=$(sanitize_arg $(b.opt.get_opt --date))

        # Run all functions to create zip files
        getLicensesFiles
        makeWindows
        makeMacOS
        makeUbuntu
        makeFedora
        makeDebian
        makeSuse
        makeSources

    fi
}



b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
