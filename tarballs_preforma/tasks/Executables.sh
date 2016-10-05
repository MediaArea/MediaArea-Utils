# MediaArea-Utils/tarballs_preforma/tasks/Executables.sh
# Generate the tarballs asked by Preforma — executables

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function makeWindows () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Windows files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/MediaConch_GUI_${MC_version}_Windows.exe"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/MediaConch_Server_${MC_version}_Windows_i386.zip"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/MediaConch_Server_${MC_version}_Windows_x64.zip"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/MediaConch_CLI_${MC_version}_Windows_i386.zip"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/MediaConch_CLI_${MC_version}_Windows_x64.zip"

    echo "Create Windows package"
    cp License*.html tmp/
    zip -q -j exec01-$Date.zip tmp/*

    rm -fr tmp
}

function makeMac () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Mac files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/MediaConch_GUI_${MC_version}_Mac.dmg"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/MediaConch_Server_${MC_version}_Mac.dmg"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/MediaConch_CLI_${MC_version}_Mac.dmg"

    echo "Create Mac package"
    cp License*.html tmp/
    zip -q -j exec05-$Date.zip tmp/*

    rm -fr tmp
}

function makeUbuntu () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Ubuntu files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0v5_${MIL_version}-1_i386.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0v5_${ZL_version}-1_i386.xUbuntu_16.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0v5_${MIL_version}-1_amd64.xUbuntu_16.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0v5_${ZL_version}-1_amd64.xUbuntu_16.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0v5_${MIL_version}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0v5_${ZL_version}-1_i386.xUbuntu_15.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0v5_${MIL_version}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0v5_${ZL_version}-1_amd64.xUbuntu_15.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.xUbuntu_15.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.xUbuntu_15.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.xUbuntu_14.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.xUbuntu_14.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.xUbuntu_14.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.xUbuntu_14.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.xUbuntu_12.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.xUbuntu_12.04.deb"

    echo "Create Ubuntu package"
    cp License*.html tmp/
    zip -q -j exec09-$Date.zip tmp/*

    rm -fr tmp
}

function makeFedora () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Fedora files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i686.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i686.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i686.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.i686.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i686.Fedora_24.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.x86_64.Fedora_24.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.Fedora_24.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i686.Fedora_23.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.Fedora_23.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i686.Fedora_22.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.Fedora_22.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i686.Fedora_21.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.Fedora_21.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i686.Fedora_20.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo-${MIL_version}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.Fedora_20.rpm"

    echo "Create Fedora package"
    cp License*.html tmp/
    zip -q -j exec13-$Date.zip tmp/*

    rm -fr tmp
}

function makeDebian () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Debian files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.Debian_8.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.Debian_8.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_i386.Debian_7.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui_${MC_version}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server_${MC_version}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch_${MC_version}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0_${MIL_version}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen0_${ZL_version}-1_amd64.Debian_7.0.deb"

    echo "Create Debian package"
    cp License*.html tmp/
    zip -q -j exec17-$Date.zip tmp/*

    rm -fr tmp
}

function makeOpensuse () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Opensuse files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_Leap_42.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i586.openSUSE_Factory.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_Factory.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i586.openSUSE_Tumbleweed.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_Tumbleweed.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i586.openSUSE_13.2.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_13.2.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i586.openSUSE_13.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-server/${MC_version}/mediaconch-server-${MC_version}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_13.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.i586.openSUSE_11.4.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${MC_version}/mediaconch-gui-${MC_version}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${MC_version}/mediaconch-${MC_version}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${MIL_version}/libmediainfo0-${MIL_version}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${ZL_version}/libzen-${ZL_version}.x86_64.openSUSE_11.4.rpm"

    echo "Create Opensuse package"
    cp License*.html tmp/
    zip -q -j exec21-$Date.zip tmp/*

    rm -fr tmp
}

function btask.Executables.run () {

    makeWindows
    makeMac
    makeUbuntu
    makeFedora
    makeDebian
    makeOpensuse

}
