# ZenLib/Release/PrepareSource.sh
# Prepare the source of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function _get_source () {

    cd "$WDir"
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of ZenLib
    if [ $(b.opt.get_opt --source-path) ]; then
        ZL_source="$SDir"
    else
        ZL_source="$WDir"/repos/ZenLib
        getRepo $Repo "$ZL_source"
        # We ask a specific git state (a tag, a branch, a commit)
        if [ $(b.opt.get_opt --git-state) ]; then
            cd "$ZL_source"
            git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        fi
    fi

}

function _unix () {

    echo
    echo "Generate the ZL directory for compilation under Unix:"
    echo "1: copy what is wanted..."

    cd "$WDir"/ZL
    cp -r "$ZL_source" ZenLib_compilation_under_unix
    chmod +x ZenLib_compilation_under_unix/Project/GNU/Library/autogen.sh

    echo "2: remove what isn’t wanted..."
    cd ZenLib_compilation_under_unix
        rm -fr .cvsignore .git*
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec GNU/PKGBUILD
            rm -fr BCB CodeBlocks Coverity
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Source/Doc Source/Example
    cd ..

}

function _all_inclusive () {

    echo
    echo "Generate the ZL all inclusive tarball:"
    echo "1: copy what is wanted..."

    cd "$WDir"/ZL
    cp -r "$ZL_source" ZenLib_AllInclusive

    echo "2: remove what isn’t wanted..."
    cd ZenLib_AllInclusive
        rm -fr .cvsignore .git*
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec GNU/PKGBUILD
            rm -fr Solaris
        cd ..
    cd ..

}

function _source_package () {

    echo
    echo "Generate the ZL directory for the source package:"
    echo "1: copy what is wanted..."

    cd "$WDir"/ZL
    cp -r "$ZL_source" .

    echo "2: remove what isn’t wanted..."
    cd ZenLib
        rm -fr .cvsignore .git*
    cd ..
    if $MakeArchives; then
        echo "3: compressing..."
        cd "$WDir"/ZL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (GZIP=-9 tar -cz --owner=root --group=root -f ../archives/libzen${Version}.tar.gz ZenLib)
        (BZIP=-9 tar -cj --owner=root --group=root -f ../archives/libzen${Version}.tar.bz2 ZenLib)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/libzen${Version}.tar.xz ZenLib)

        mkdir ../archives/obs

        cp ../archives/libzen${Version}.tar.xz ../archives/obs/libzen${Version}.orig.tar.xz
        cp ../archives/libzen${Version}.tar.gz ../archives/obs
        cp "$WDir/ZL/ZenLib/Project/GNU/libzen.spec" ../archives/obs
        cp "$WDir/ZL/ZenLib/Project/GNU/PKGBUILD" ../archives/obs

        update_pkgbuild ../archives/obs/libzen${Version}.orig.tar.xz ../archives/obs/PKGBUILD
        deb_obs ZenLib "$WDir/ZL/ZenLib" "$WDir/archives/obs/libzen${Version}.orig.tar.xz"
    fi

}

function btask.PrepareSource.run () {
    local ZL_source

    cd "$WDir"

    # Clean up
    rm -fr archives
    rm -fr repos/ZenLib
    rm -fr "$WDir"/ZL
    mkdir "$WDir"/ZL

    _get_source

    if [ -z "$Version" ] ; then
        Version=_$(cat "$ZL_source/Project/version.txt")
    fi

    if [ "$Target" = "cu" ] || [ "$Target" = "all" ] ; then
        _unix
    fi
    if [ "$Target" = "ai" ] || [ "$Target" = "all" ] ; then
        _all_inclusive
    fi
    if [ "$Target" = "sa" ] || [ "$Target" = "all" ] ; then
        _source_package
    fi

    if $CleanUp; then
        cd "$WDir"
        rm -fr repos
        rm -fr ZL
    fi

}
