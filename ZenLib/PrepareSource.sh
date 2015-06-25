# ZenLib/Release/PrepareSource.sh
# Prepare the source of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

function _get_source () {

    local RepoURL

    if [ $(b.opt.get_opt --repo) ]; then
        RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        RepoURL="https://github.com/MediaArea/"
    fi

    cd $WPath
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of ZenLib
    if [ $(b.opt.get_opt --source-path) ]; then
        ZL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo ZenLib $RepoURL $WPath/repos
        ZL_source=$WPath/repos/ZenLib
    fi

}

function _compil_unix () {

    echo
    echo "Generate the ZL directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source ZenLib${Version}_compilation_under_unix

    echo "2: remove what isn't wanted..."
    cd ZenLib${Version}_compilation_under_unix
        rm -fr .cvsignore .git*
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec
            rm -fr BCB CMake CodeBlocks Coverity
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Source/Doc Source/Example
    cd ..

}

function _compil_windows () {

    echo
    echo "Generate the ZL directory for compilation under Windows:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source ZenLib${Version}_compilation_under_windows

    echo "2: remove what isn't wanted..."
    cd ZenLib${Version}_compilation_under_windows
        rm -fr .cvsignore .git*
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec
            rm -fr Solaris
        cd ..
    cd ..

}

function _linux_packages () {

    echo
    echo "Generate the ZL directory for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source .

    echo "2: remove what isn't wanted..."
    cd ZenLib
        rm -fr .cvsignore .git*
        #rm -fr Release
        cd Project
            rm -fr BCB CMake CodeBlocks Coverity
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
    cd ..
    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/ZL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (XZ_OPT=-9 tar -cJ --owner=root --group=root -f ../archives/libzen${Version}.txz ZenLib)
    fi

}

function btask.PrepareSource.run () {

    local ZL_source

    cd $WPath

    # Clean up
    rm -fr archives
    rm -fr repos/ZenLib
    rm -fr $WPath/ZL
    mkdir $WPath/ZL

    _get_source

    if [ "$Target" = "cu" ]; then
        _compil_unix
    fi
    if [ "$Target" = "cw" ]; then
        _compil_windows
    fi
    if [ "$Target" = "lp" ]; then
        _linux_packages
    fi
    if [ "$Target" = "all" ]; then
        _compil_unix
        _compil_windows
        _linux_packages
    fi

    if $CleanUp; then
        cd $WPath
        rm -fr repos
        rm -fr ZL
    fi

}
