# dvrescue/Release/PrepareSource.sh
# Prepare the source of dvrescue

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _get_source () {

    local MIL_gs ZL_gs MIL_repo ZL_repo

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

    MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi
    ZL_gs=""
    if [ $(b.opt.get_opt --zl-gs) ]; then
        ZL_gs="--zl-gs $(sanitize_arg $(b.opt.get_opt --zl-gs))"
    fi
    MIL_repo=""
    if [ $(b.opt.get_opt --mil-repo) ]; then
        MIL_repo="--repo $(sanitize_arg $(b.opt.get_opt --mil-repo))"
    fi
    ZL_repo=""
    if [ $(b.opt.get_opt --zl-repo) ]; then
        ZL_repo="--zl-repo $(sanitize_arg $(b.opt.get_opt --zl-repo))"
    fi

    # MediaInfoLib (will also bring ZenLib and zlib)
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if b.path.dir? "$WDir/../upgrade_version/MediaInfoLib" ; then
         $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -sp "$WDir/../upgrade_version/MediaInfoLib" -wp "$WDir" $ZL_repo $ZL_gs -${Target} -na
    else
        $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -wp "$WDir" $MIL_repo $ZL_repo $MIL_gs $ZL_gs -${Target} -na
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
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/ZenLib .
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/MediaInfoLib .

    # Dependency : zlib
    cp -r "$WDir"/MIL/MediaInfo_DLL_GNU_FromSource/Shared .

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

function _all_inclusive () {

    echo
    echo "Generate the DR all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/DR
    mkdir dvrescue_AllInclusive
    cd dvrescue_AllInclusive

    cp -r "$DR_source" .

    # Dependencies
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/ZenLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/MediaInfoLib .
    cp -r "$WDir"/MIL/libmediainfo_AllInclusive/zlib .

    echo "2: remove what isn’t wanted..."
    pushd dvrescue
        rm -fr .git*
        rm -fr Project/Mac
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

        mkdir ../archives/obs

        cp ../archives/dvrescue${Version}.tar.xz ../archives/obs/dvrescue${Version}.orig.tar.xz
        cp ../archives/dvrescue${Version}.tar.gz ../archives/obs
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
    rm -fr ZL
    rm -fr MIL
    rm -fr DR
    mkdir DR

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$DR_source/Project/version.txt")
    fi

    if [ "$Target" = "cu" ]; then
        _unix_cli
    fi
    if [ "$Target" = "ai" ]; then
        _all_inclusive
    fi
    if [ "$Target" = "sa" ]; then
        _source_package
    fi
    if [ "$Target" = "all" ]; then
        _unix_cli
        _all_inclusive
        _source_package
    fi
    
    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr ZL
        rm -fr MIL
        rm -fr DR
    fi

}
