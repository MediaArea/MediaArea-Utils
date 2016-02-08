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
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/MediaConch_GUI_${mc}_Windows.exe"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Windows_i386.zip"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Windows_x64.zip"

    echo "Create Windows package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
    zip -q -j exec01-$Date.zip tmp/*

    rm -fr tmp
}

function makeMacOS () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Mac OS files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/MediaConch_GUI_${mc}_Mac.dmg"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/MediaConch_CLI_${mc}_Mac.dmg"

    echo "Create Mac OS package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
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
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0v5_${mil}-1_i386.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0v5_${zl}-1_i386.xUbuntu_15.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0v5_${mil}-1_amd64.xUbuntu_15.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0v5_${zl}-1_amd64.xUbuntu_15.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_15.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_15.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_15.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_14.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_14.10.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_14.10.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_14.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_14.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_14.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.xUbuntu_12.04.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.xUbuntu_12.04.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.xUbuntu_12.04.deb"

    echo "Create Ubuntu package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
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
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_23.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_23.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_23.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_22.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_22.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_22.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_21.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_21.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_21.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i686.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i686.Fedora_20.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.Fedora_20.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.Fedora_20.rpm"

    echo "Create Fedora package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
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
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.Debian_8.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.Debian_8.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.Debian_8.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_i386.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_i386.Debian_7.0.deb"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui_${mc}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch_${mc}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0_${mil}-1_amd64.Debian_7.0.deb"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0_${zl}-1_amd64.Debian_7.0.deb"

    echo "Create Debian package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
    zip -q -j exec17-$Date.zip tmp/*

    rm -fr tmp
}

function makeSuse () {
    if b.path.dir? tmp; then
        rm -fr tmp/*;
    else
        mkdir tmp
    fi

    echo "Download Suse files"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Leap_42.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Leap_42.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_Factory.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Factory.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Factory.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_Tumbleweed.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_Tumbleweed.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_Tumbleweed.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_13.2.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_13.2.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_13.2.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_13.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_13.1.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_13.1.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.i586.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.i586.openSUSE_11.4.rpm"

    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch-gui/${mc}/mediaconch-gui-${mc}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/mediaconch/${mc}/mediaconch-${mc}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libmediainfo0/${mil}/libmediainfo0-${mil}.x86_64.openSUSE_11.4.rpm"
    wget -nd -q -P tmp "https://mediaarea.net/download/binary/libzen0/${zl}/libzen0-${zl}.x86_64.openSUSE_11.4.rpm"

    echo "Create Suse package"
    cp MediaArea/MediaConch_SourceCode/master/License*.html tmp/
    zip -q -j exec21-$Date.zip tmp/*

    rm -fr tmp
}

function btask.Executables.run () {

    makeWindows
    makeMacOS
    makeUbuntu
    makeFedora
    makeDebian
    makeSuse

}
