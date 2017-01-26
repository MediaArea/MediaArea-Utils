# MediaInfoLib/Release/PrepareSource.sh
# Prepare the source of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _get_source () {

    local ZL_gs

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of MediaInfoLib
    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source="$SDir"
    else
        MIL_source="$WDir"/repos/MediaInfoLib
        getRepo $Repo "$MIL_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$MIL_source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

    ZL_gs=""
    if [ $(b.opt.get_opt --zl-gs) ]; then
        ZL_gs="-gs $(sanitize_arg $(b.opt.get_opt --zl-gs))"
    fi

    # Dependency : ZenLib
    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    $(b.get bang.src_path)/bang run PrepareSource.sh -p ZenLib -wp "$WDir" $ZL_gs -${Target} -na

    # Dependency : zlib
    cd "$WDir"/repos
    git clone --depth 1 https://github.com/MediaArea/zlib

}

function _unix () {

    echo
    echo "Generate the MIL directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MIL
    mkdir MediaInfo_DLL_GNU_FromSource
    cd MediaInfo_DLL_GNU_FromSource

    cp -r "$MIL_source" .
    mv MediaInfoLib/Project/GNU/Library/AddThisToRoot_DLL_compile.sh SO_Compile.sh
    chmod +x SO_Compile.sh
    chmod +x MediaInfoLib/Project/GNU/Library/autogen.sh
    chmod +x MediaInfoLib/Project/Mac/BR_extension_SO.sh
    chmod +x MediaInfoLib/Project/Mac/Make_tarball.sh

    # Dependency : ZenLib
    cp -r "$WDir"/ZL/ZenLib_compilation_under_unix ZenLib

    # Dependency : zlib
    mkdir -p Shared/Project/zlib
    mv MediaInfoLib/Project/zlib/Compile.sh Shared/Project/zlib

    echo "2: remove what isn’t wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
        rm -fr debian
        cd Project
            rm -f GNU/libmediainfo.dsc GNU/libmediainfo.spec GNU/PKGBUILD
            rm -fr OBS Solaris
            rm -fr MSCS2008 MSCS2010 MSJS MSVB MSVB2010
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013 zlib
            rm -fr BCB CodeBlocks Coverity Delphi Java NetBeans
            rm -fr PureBasic
        cd ..
    cd ..

    echo "3: Autotools..."
    cd ZenLib/Project/GNU/Library
    ./autogen.sh > /dev/null 2>&1
    cd ../../../../MediaInfoLib/Project/GNU/Library
    ./autogen.sh > /dev/null 2>&1
    cd ../../../..

    echo "4: Doxygen..."
    cd MediaInfoLib/Source/Doc
    doxygen

    if $MakeArchives; then
        echo "5: compressing..."
        cd "$WDir"/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_DLL${Version}_GNU_FromSource.tar.gz MediaInfo_DLL_GNU_FromSource)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_DLL${Version}_GNU_FromSource.tar.bz2 MediaInfo_DLL_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_DLL${Version}_GNU_FromSource.tar.xz MediaInfo_DLL_GNU_FromSource)
    fi

}

function _all_inclusive () {

    echo
    echo "Generate the MIL all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MIL
    mkdir libmediainfo${Version}_AllInclusive
    cd libmediainfo${Version}_AllInclusive

    cp -r "$MIL_source" .

    # Dependency : ZenLib
    cp -r "$WDir"/ZL/ZenLib_AllInclusive ZenLib

    # Dependency : zlib
    cp -r "$WDir"/repos/zlib .
    rm -fr zlib/.git zlib/examples zlib/doc
    mv MediaInfoLib/Project/zlib/projects zlib

    echo "2: remove what isn’t wanted..."
    cd MediaInfoLib
        rm -f .cvsignore .gitignore
        rm -fr .git
        rm -fr debian
        rm -fr Project/Solaris Project/zlib
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7za a -t7z -mx=9 -bd ../archives/libmediainfo${Version}_AllInclusive.7z libmediainfo${Version}_AllInclusive >/dev/null
    fi

}

function _source_package () {

    echo
    echo "Generate the MIL directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/MIL
    cp -r "$MIL_source" .

    echo "2: remove what isn’t wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/libmediainfo${Version}.tar.gz MediaInfoLib)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/libmediainfo${Version}.tar.bz2 MediaInfoLib)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/libmediainfo${Version}.tar.xz MediaInfoLib)
    fi

}

function btask.PrepareSource.run () {

    local MIL_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/ZenLib
    rm -fr repos/MediaInfoLib
    rm -fr repos/zlib
    rm -fr ZL
    rm -fr MIL
    mkdir MIL

    _get_source

    if [ "$Target" = "cu" ]; then
        _unix
    fi
    if [ "$Target" = "ai" ]; then
        _all_inclusive
    fi
    if [ "$Target" = "sa" ]; then
        _source_package
    fi
    if [ "$Target" = "all" ]; then
        _unix
        _all_inclusive
        _source_package
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr MIL
        rm -fr ZL
    fi

}
