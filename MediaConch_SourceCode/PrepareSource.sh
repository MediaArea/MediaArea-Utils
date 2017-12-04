# MediaConch_SourceCode/Release/PrepareSource.sh
# Prepare the source of MediaConch

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

    # Determine where are the sources of MediaConch
    if [ $(b.opt.get_opt --source-path) ]; then
        MC_source="$SDir"
    else
        MC_source="$WDir"/repos/MediaConch_SourceCode
        getRepo $Repo "$MC_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$MC_source"
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

    cd "$WDir"/repos

    # zlib, libxml2, libxslt, jansson, libevent, sqlite
    git clone --depth 1 https://github.com/MediaArea/zlib.git
    git clone --depth 1 https://git.gnome.org/browse/libxml2
    git clone --depth 1 https://git.gnome.org/browse/libxslt
    git clone --depth 1 https://github.com/MediaArea/jansson.git
    git clone --depth 1 https://github.com/MediaArea/libevent.git
    curl -s http://www.sqlite.org/2017/sqlite-autoconf-3180000.tar.gz | tar -xzp
    mv sqlite-autoconf-3180000 sqlite


    # MediaInfoLib (will also bring ZenLib and zlib)
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if b.path.dir? "$WDir/../repos/MediaInfoLib" ; then
         $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -sp "$WDir/../repos/MediaInfoLib" -wp "$WDir" $ZL_gs -${Target} -na
    else
        $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -wp "$WDir" $MIL_gs $ZL_gs -${Target} -na
    fi
}

function _unix_cli () {

    echo
    echo "Generate the MC CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MC
    mkdir MediaConch_CLI_GNU_FromSource
    cd MediaConch_CLI_GNU_FromSource

    cp -a "$MC_source" MediaConch
    mv MediaConch/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x MediaConch/Project/GNU/CLI/autogen.sh
    chmod +x MediaConch/Project/Mac/BR_extension_CLI.sh
    chmod +x MediaConch/Project/Mac/Make_MC_dmg.sh

    # ZenLib and MediaInfoLib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

    mkdir -p Shared/Source
    cp -a "$WDir"/repos/zlib Shared/Source

    # ? Dependencies : libxml2...
    cp -a "$WDir"/repos/libxml2 .
    cp -a "$WDir"/repos/libxslt .
    cp -a "$WDir"/repos/jansson .
    cp -a "$WDir"/repos/libevent .
    cp -a "$WDir"/repos/sqlite .

    rm -fr {Shared/Source/zlib,libxml2,libxslt,jansson,libevent}/.git*

    echo "2: remove what isn’t wanted..."
    cd MediaConch
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/GUI Mac/*_GUI.sh
            rm -f GNU/mediaconch.dsc GNU/mediaconch.spec GNU/PKGBUILD
            rm -fr OBS
            rm -fr MSVC2013
        cd ..
        rm -fr Source/GUI
    cd ..

    echo "3: Autotools..."
    (cd MediaConch/Project/GNU/CLI && ./autogen.sh > /dev/null 2>&1)
    (cd libxml2 && autoreconf -i -f > /dev/null 2>&1)
    (cd libxslt && autoreconf -i -f > /dev/null 2>&1)
    (cd jansson && autoreconf -i -f  > /dev/null 2>&1)
    (cd libevent && autoreconf -i -f > /dev/null 2>&1)

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaConch_CLI${Version}_GNU_FromSource.tar.gz MediaConch_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaConch_CLI${Version}_GNU_FromSource.tar.bz2 MediaConch_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaConch_CLI${Version}_GNU_FromSource.tar.xz MediaConch_CLI_GNU_FromSource)
    fi

}

function _unix_server () {

    echo
    echo "Generate the MC server directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MC
    mkdir MediaConch_Server_GNU_FromSource
    cd MediaConch_Server_GNU_FromSource

    cp -a "$MC_source" MediaConch
    mv MediaConch/Project/GNU/Server/AddThisToRoot_Server_compile.sh Server_Compile.sh
    chmod +x Server_Compile.sh
    chmod +x MediaConch/Project/GNU/Server/autogen.sh
    chmod +x MediaConch/Project/Mac/BR_extension_Server.sh
    chmod +x MediaConch/Project/Mac/Make_MC_dmg.sh

    # ZenLib and MediaInfoLib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .


    mkdir -p Shared/Source
    cp -a "$WDir"/repos/zlib Shared/Source

    # ? Dependencies : libxml2...
    cp -a "$WDir"/repos/libxml2 .
    cp -a "$WDir"/repos/libxslt .
    cp -a "$WDir"/repos/jansson .
    cp -a "$WDir"/repos/libevent .
    cp -a "$WDir"/repos/sqlite .

    rm -fr {Shared/Source/zlib,libxml2,libxslt,jansson,libevent}/.git*

    echo "2: remove what isn’t wanted..."
    cd MediaConch
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/CLI Mac/*_CLI.sh
            rm -fr GNU/GUI Mac/*_GUI.sh
            rm -f GNU/mediaconch.dsc GNU/mediaconch.spec GNU/PKGBUILD
            rm -fr OBS
            rm -fr MSVC2013
        cd ..
        rm -fr Source/GUI
    cd ..

    echo "3: Autotools..."
    (cd MediaConch/Project/GNU/Server && ./autogen.sh > /dev/null 2>&1)
    (cd libxml2 && autoreconf -i -f > /dev/null 2>&1)
    (cd libxslt && autoreconf -i -f > /dev/null 2>&1)
    (cd jansson && autoreconf -i -f > /dev/null 2>&1)
    (cd libevent && autoreconf -i -f > /dev/null 2>&1)

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaConch_Server${Version}_GNU_FromSource.tar.gz MediaConch_Server_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaConch_Server${Version}_GNU_FromSource.tar.bz2 MediaConch_Server_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaConch_Server${Version}_GNU_FromSource.tar.xz MediaConch_Server_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the MC GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MC
    mkdir MediaConch_GUI_GNU_FromSource
    cd MediaConch_GUI_GNU_FromSource

    cp -a "$MC_source" MediaConch
    mv MediaConch/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x MediaConch/Project/Qt/prepare
    chmod +x MediaConch/Project/Mac/BR_extension_GUI.sh
    chmod +x MediaConch/Project/Mac/Make_MC_dmg.sh
    chmod +x MediaConch/Project/Mac/Make_MC_xcarchive.sh

    # ZenLib and MediaInfoLib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -a "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

    mkdir -p Shared/Source
    cp -a "$WDir"/repos/zlib Shared/Source

    # ? Dependencies : libxml2...
    cp -a "$WDir"/repos/libxml2 .
    cp -a "$WDir"/repos/libxslt .
    cp -a "$WDir"/repos/jansson .
    cp -a "$WDir"/repos/libevent .
    cp -a "$WDir"/repos/sqlite .

    rm -fr {Shared/Source/zlib,libxml2,libxslt,jansson,libevent}/.git*

    echo "2: remove what isn’t wanted..."
    cd MediaConch
        rm -fr .cvsignore .git*
        rm -f History_CLI.txt
        rm -fr debian
        cd Project
            rm -fr GNU/CLI Mac/*_CLI.sh
            rm -f GNU/mediaconch.dsc GNU/mediaconch.spec GNU/PKGBUILD
            rm -fr OBS
            rm -fr MSVC2013
        cd ..
    cd ..

    echo "3: Autotools..."
    (cd libxml2 && autoreconf -i -f > /dev/null 2>&1)
    (cd libxslt && autoreconf -i -f > /dev/null 2>&1)
    (cd jansson && autoreconf -i -f > /dev/null 2>&1)
    (cd libevent && autoreconf -i -f > /dev/null 2>&1)

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/MC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaConch_GUI${Version}_GNU_FromSource.tar.gz MediaConch_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaConch_GUI${Version}_GNU_FromSource.tar.bz2 MediaConch_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaConch_GUI${Version}_GNU_FromSource.tar.xz MediaConch_GUI_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the MC all inclusive tarball:"
    echo "1: get the sources..."

    cd "$WDir"/MC
    mkdir mediaconch_AllInclusive
    cd mediaconch_AllInclusive

    git clone --recursive https://github.com/MediaArea/MediaConch-AllInOne .
    # Update submodules
    git submodule update --remote

    # Use local MediaConch source tree if aviable
    if [ "$Target" != "ai" ]; then
        rm -fr MediaConch
        cp -a "$MC_source" MediaConch
    fi

    echo "2: remove what isn’t wanted..."
    rm -fr .git* */*.git*

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/mediaconch${Version}_AllInclusive.7z mediaconch_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the MC directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MC

    cp -a "$MC_source" MediaConch

    echo "2: remove what isn’t wanted..."
    cd MediaConch
        rm -fr .cvsignore .git*
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MC
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/mediaconch${Version}.tar.gz MediaConch)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/mediaconch${Version}.tar.bz2 MediaConch)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/mediaconch${Version}.tar.xz MediaConch)

        mkdir ../archives/obs

        cp ../archives/mediaconch${Version}.tar.xz ../archives/obs/mediaconch${Version}.orig.tar.xz
        cp ../archives/mediaconch${Version}.tar.gz ../archives/obs
        cp "$WDir/MC/MediaConch/Project/GNU/mediaconch.spec" ../archives/obs
        cp "$WDir/MC/MediaConch/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/mediaconch${Version}.orig.tar.xz ../archives/obs/PKGBUILD
        deb_obs MediaConch "$WDir/MC/MediaConch" "$WDir/archives/obs/mediaconch${Version}.orig.tar.xz"
    fi

}

function btask.PrepareSource.run () {

    local MC_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr ZL
    rm -fr MIL
    rm -fr MC
    mkdir MC

    # No need to get the source normally if we want the all
    # inclusive tarball.
    if ! [ "$Target" = "ai" ]; then
        _get_source

        if [ -z "$Version" ] ; then
            Version=_$(cat "$MC_source/Project/version.txt")
        fi
    fi

    if [ "$Target" = "cu" ]; then
        _unix_cli
        _unix_server
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
        _unix_server
        _unix_gui
        _all_inclusive
        _source_package
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr ZL
        rm -fr MIL
        rm -fr MC
    fi

}
