# MediaInfo/Release/PrepareSource.sh
# Prepare the source of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _get_source () {

    local MIL_gs ZL_gs

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of MediaInfo
    if [ $(b.opt.get_opt --source-path) ]; then
        MI_source="$SDir"
    else
        MI_source="$WDir"/repos/MediaInfo
        getRepo $Repo "$MI_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$MI_source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

    MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi
    ZL_gs=""
    if [ $(b.opt.get_opt --zl-gs) ]; then
        ZL_gs="--zl-gs $(sanitize_arg $(b.opt.get_opt --zl-gs))"
    fi

    # MediaInfoLib (will also bring ZenLib and zlib)
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if b.path.dir? "$WDir/../upgrade_version/MediaInfoLib" ; then
         $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -sp "$WDir/../upgrade_version/MediaInfoLib" -wp "$WDir" $ZL_gs -${Target} -na
    else
        $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -wp "$WDir" $MIL_gs $ZL_gs -${Target} -na
    fi

}

function _unix_cli () {

    echo
    echo "Generate the MI CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MI
    mkdir MediaInfo_CLI_GNU_FromSource
    cd MediaInfo_CLI_GNU_FromSource

    cp -r "$MI_source" .
    mv MediaInfo/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x MediaInfo/Project/GNU/CLI/autogen.sh
    chmod +x MediaInfo/Project/Mac/BR_extension_CLI.sh
    chmod +x MediaInfo/Project/Mac/Make_MI_dmg.sh

    # ZenLib and MediaInfoLib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

    echo "2: remove what isn’t wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/GUI Mac/*_GUI.sh Mac/Prepare_for_Xcode.sh
            rm -fr WxWidgets
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec GNU/PKGBUILD
            rm -fr OBS Solaris
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr BCB QMake CodeBlocks
        cd ..
        rm -fr Source/GUI
    cd ..

    echo "3: Autotools..."
    cd MediaInfo/Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tar.gz MediaInfo_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tar.bz2 MediaInfo_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tar.xz MediaInfo_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the MI GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MI
    mkdir MediaInfo_GUI_GNU_FromSource
    cd MediaInfo_GUI_GNU_FromSource

    cp -r "$MI_source" .
    mv MediaInfo/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x MediaInfo/Project/GNU/GUI/autogen.sh
    chmod +x MediaInfo/Project/Mac/BR_extension_GUI.sh
    chmod +x MediaInfo/Project/Mac/Prepare_for_Xcode.sh
    chmod +x MediaInfo/Project/Mac/Make_MI_dmg.sh

    # ZenLib and MediaInfoLib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .
    # Dependency : wxWidgets
    mv MediaInfo/Project/WxWidgets Shared/Project

    echo "2: remove what isn’t wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_CLI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/CLI Mac/*_CLI.sh
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec GNU/PKGBUILD
            rm -fr OBS Solaris
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr BCB QMake CodeBlocks
        cd ..
        # Don’t delete CLI source, required for command-line parsing
    cd ..

    echo "3: Autotools..."
    cd MediaInfo/Project/GNU/GUI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tar.gz MediaInfo_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tar.bz2 MediaInfo_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tar.xz MediaInfo_GUI_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the MI all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MI
    mkdir mediainfo_AllInclusive
    cd mediainfo_AllInclusive

    cp -r "$MI_source" .

    # Dependencies
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/ZenLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/MediaInfoLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/zlib .

    wget -q https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.0/wxWidgets-3.1.0.7z
    7z x wxWidgets-3.1.0.7z -owxWidgets
    rm -f wxWidgets-3.1.0.7z

    echo "2: remove what isn’t wanted..."
    cd MediaInfo
        rm -f .cvsignore .gitignore
        rm -fr .git
        rm -fr debian
        cd Project
            rm -fr OBS Mac Solaris
        cd ..
        rm -fr Source/GUI/Cocoa
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/mediainfo${Version}_AllInclusive.7z mediainfo_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the MI directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MI
    cp -r "$MI_source" .

    echo "2: remove what isn’t wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/mediainfo${Version}.tar.gz MediaInfo)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/mediainfo${Version}.tar.bz2 MediaInfo)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/mediainfo${Version}.tar.xz MediaInfo)

        mkdir ../archives/obs

        cp ../archives/mediainfo${Version}.tar.xz ../archives/obs/mediainfo${Version}.orig.tar.xz
        cp ../archives/mediainfo${Version}.tar.gz ../archives/obs
        cp "$WDir/MI/MediaInfo/Project/GNU/mediainfo.spec" ../archives/obs
        cp "$WDir/MI/MediaInfo/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/mediainfo${Version}.orig.tar.xz ../archives/obs/PKGBUILD
        deb_obs MediaInfo "$WDir/MI/MediaInfo" "$WDir/archives/obs/mediainfo${Version}.orig.tar.xz"
    fi

}

function btask.PrepareSource.run () {

    local MI_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr ZL
    rm -fr MIL
    rm -fr MI
    mkdir MI

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$MI_source/Project/version.txt")
    fi

    if [ "$Target" = "cu" ]; then
        _unix_cli
        _unix_gui
    fi
    if [ "$Target" = "ai" ]; then
        _all_inclusive
    fi
    if [ "$Target" = "sa" ]; then
        _source_package
    fi
    if [ "$Target" = "all" ]; then
        _unix_cli
        _unix_gui
        _all_inclusive
        _source_package
    fi
    
    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr ZL
        rm -fr MIL
        rm -fr MI
    fi

}
