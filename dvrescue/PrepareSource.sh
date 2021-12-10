# dvrescue/Release/PrepareSource.sh
# Prepare the source of dvrescue

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _get_source () {

    local MI_gs MIL_gs ZL_gs MI_repo MIL_repo ZL_repo

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of dvrescue
    if [ $(b.opt.get_opt --source-path) ]; then
        DR_source="$SDir"
    else
        DR_source="$WDir"/repos/dvrescue
        getRepo $Repo "$DR_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$DR_source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi
    cd "$WDir"

    MI_gs=""
    if [ $(b.opt.get_opt --mi-gs) ]; then
        MI_gs="-gs $(sanitize_arg $(b.opt.get_opt --mi-gs))"
    fi
    MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="--mil-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi
    ZL_gs=""
    if [ $(b.opt.get_opt --zl-gs) ]; then
        ZL_gs="--zl-gs $(sanitize_arg $(b.opt.get_opt --zl-gs))"
    fi
    MI_repo=""
    if [ $(b.opt.get_opt --mi-repo) ]; then
        MI_repo="--repo $(sanitize_arg $(b.opt.get_opt --mi-repo))"
    fi
    MIL_repo=""
    if [ $(b.opt.get_opt --mil-repo) ]; then
        MIL_repo="--mil-repo $(sanitize_arg $(b.opt.get_opt --mil-repo))"
    fi
    ZL_repo=""
    if [ $(b.opt.get_opt --zl-repo) ]; then
        ZL_repo="--zl-repo $(sanitize_arg $(b.opt.get_opt --zl-repo))"
    fi

    # Qwt
    curl -LO https://github.com/opencor/qwt/archive/master.zip
    unzip master.zip
    mv qwt-master qwt
    rm master.zip

    (cd qwt && curl -L https://github.com/ElderOrb/qwt/commit/3e72164e902cf7a690d19cc0cdf44f9faebbcdc8.patch | patch -p1)

    # ffmpeg
    git clone --depth 1 --branch n4.4.1 "https://git.ffmpeg.org/ffmpeg.git" ffmpeg
    curl -LO https://gist.githubusercontent.com/g-maxime/a8d40c5167d5326e2858718b9476494b/raw/8d2d0d34902bdac4e4cc50de187651f930df932a/ffmpeg-av.diff
    (cd ffmpeg && git apply < ../ffmpeg-av.diff)
    rm ffmpeg-av.diff

    # yasm
    curl -LO http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
    tar -zxf yasm-1.3.0.tar.gz
    mv yasm-1.3.0 yasm
    rm yasm-1.3.0.tar.gz

    # xmlstarlet
    curl -LO http://downloads.sourceforge.net/project/xmlstar/xmlstarlet/1.6.1/xmlstarlet-1.6.1.tar.gz
    tar -zxf xmlstarlet-1.6.1.tar.gz
    mv xmlstarlet-1.6.1 xmlstarlet
    rm xmlstarlet-1.6.1.tar.gz

    # MediaInfo (will also bring MediaInfoLib, ZenLib and zlib)
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if b.path.dir? "$WDir/../upgrade_version/MediaInfo" ; then
         $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfo -sp "$WDir/../upgrade_version/MediaInfo" -wp "$WDir" $MIL_repo $ZL_repo $MIL_gs $ZL_gs -${Target} -na
    else
        $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfo -wp "$WDir/MI" $MI_repo $MIL_repo $ZL_repo $MI_gs $MIL_gs $ZL_gs -${Target} -na
    fi
}

function _unix_cli () {

    echo
    echo "Generate the DR CLI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DR
    mkdir dvrescue_CLI_GNU_FromSource
    cd dvrescue_CLI_GNU_FromSource

    cp -r "$DR_source" .
    mv dvrescue/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh
    chmod +x CLI_Compile.sh
    chmod +x dvrescue/Project/GNU/CLI/autogen.sh
    chmod +x dvrescue/Project/Mac/BR_extension_CLI.sh
    chmod +x dvrescue/Project/Mac/mkdmg.sh

    # ZenLib and MediaInfoLib
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/Shared .

    echo "2: remove what isn’t wanted..."
    pushd dvrescue
        rm -fr .git*
        rm -fr debian
        rm -f Project/GNU/dvrescue.dsc Project/GNU/dvrescue.spec Project/GNU/PKGBUILD
    popd

    echo "3: Autotools..."
    cd dvrescue/Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "4: compressing..."
        cd "$WDir"/DR
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/dvrescue_CLI${Version}_GNU_FromSource.tar.gz dvrescue_CLI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/dvrescue_CLI${Version}_GNU_FromSource.tar.bz2 dvrescue_CLI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/dvrescue_CLI${Version}_GNU_FromSource.tar.xz dvrescue_CLI_GNU_FromSource)
    fi

}

function _unix_gui () {

    echo
    echo "Generate the DR GUI directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DR
    mkdir dvrescue_GUI_GNU_FromSource
    cd dvrescue_GUI_GNU_FromSource

    cp -r "$DR_source" .
    mv dvrescue/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh
    chmod +x GUI_Compile.sh
    chmod +x dvrescue/Project/GNU/CLI/autogen.sh
    chmod +x dvrescue/Project/Mac/BR_extension_CLI.sh
    chmod +x dvrescue/Project/Mac/BR_extension_GUI.sh
    chmod +x dvrescue/Project/Mac/mkdmg.sh

    # ZenLib, MediaInfoLib and MediaInfo
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/MediaInfoLib .
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/MediaInfo .

    # Qwt
    cp -r "$WDir"/qwt .

    # ffmpeg
    cp -r "$WDir"/ffmpeg .

    # yasm
    cp -r "$WDir"/yasm .

    # xmlstarlet
    cp -r "$WDir"/xmlstarlet .

    # Dependency : zlib
    cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/Shared .

    echo "2: remove what isn’t wanted..."
    pushd dvrescue
        rm -fr .git*
        rm -fr debian
        rm -f Project/GNU/dvrescue.dsc Project/GNU/dvrescue.spec Project/GNU/PKGBUILD
    popd
    pushd qwt
        rm -fr .git*
    popd
    pushd ffmpeg
        rm -fr .git*
    popd

    echo "3: Autotools..."
    cd dvrescue/Project/GNU/CLI
    ./autogen.sh > /dev/null 2>&1

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/DR
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/dvrescue_GUI${Version}_GNU_FromSource.tar.gz dvrescue_GUI_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/dvrescue_GUI${Version}_GNU_FromSource.tar.bz2 dvrescue_GUI_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/dvrescue_GUI${Version}_GNU_FromSource.tar.xz dvrescue_GUI_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the DR all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DR
    mkdir dvrescue_AllInclusive
    cd dvrescue_AllInclusive

    cp -r "$DR_source" .

    # Dependencies
    cp -r "$WDir"/MI/MI/mediainfo_AllInclusive/zlib .
    cp -r "$WDir"/MI/MI/mediainfo_AllInclusive/ZenLib .
    cp -r "$WDir"/MI/MI/mediainfo_AllInclusive/MediaInfoLib .
    cp -r "$WDir"/MI/MI/mediainfo_AllInclusive/MediaInfo .
    cp -r "$WDir"/ffmpeg .
    cp -r "$WDir"/yasm .
    cp -r "$WDir"/qwt .

    echo "2: remove what isn’t wanted..."
    pushd dvrescue
        rm -fr .git*
        rm -fr Project/Mac
    popd
    pushd qwt
        rm -fr .git*
    popd
    pushd ffmpeg
        rm -fr .git*
    popd

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/DR
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/dvrescue${Version}_AllInclusive.7z dvrescue_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the DR directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DR
    cp -r "$DR_source" .

    echo "2: remove what isn’t wanted..."
    pushd dvrescue
        rm -fr .git*
    popd

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/DR
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/dvrescue${Version}.tar.gz dvrescue)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/dvrescue${Version}.tar.bz2 dvrescue)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/dvrescue${Version}.tar.xz dvrescue)

        echo "4: OBS archives..."
        mkdir -p obs/dvrescue

        #OBS Dependencies
        cp -r "$DR_source" obs/dvrescue
        cp -r "$WDir"/ffmpeg obs/dvrescue
        cp -r "$WDir"/xmlstarlet obs/dvrescue
        cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/ZenLib obs/dvrescue
        cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/MediaInfoLib obs/dvrescue
        cp -r "$WDir"/MI/MI/MediaInfo_CLI_GNU_FromSource/MediaInfo obs/dvrescue
        pushd obs/dvrescue/dvrescue
            rm -fr .git*
        popd
        pushd obs/dvrescue/ffmpeg
            rm -fr .git*
        popd
        mkdir -p ../archives/obs
        pushd obs
            (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../../archives/obs/dvrescue${Version}.orig.tar.xz dvrescue)
            (GZIP=-9 tar -cz --owner=root --group=root -f ../../archives/obs/dvrescue${Version}.tar.gz dvrescue)
        popd

        cp "$WDir/DR/dvrescue/Project/GNU/dvrescue.spec" ../archives/obs
        cp "$WDir/DR/dvrescue/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/dvrescue${Version}.orig.tar.xz ../archives/obs/PKGBUILD
        deb_obs dvrescue "$WDir/DR/dvrescue" "$WDir/archives/obs/dvrescue${Version}.orig.tar.xz"
    fi

}

function btask.PrepareSource.run () {

    local DR_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr MI
    rm -fr DR
    mkdir DR

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$DR_source/Project/version.txt")
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
        rm -fr MI
        rm -fr DR
    fi

}
