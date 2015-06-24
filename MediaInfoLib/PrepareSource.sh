# MediaInfoLib/Release/PrepareSource.sh
# Prepare the source of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

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

    # Determine where are the sources of MediaInfoLib
    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo MediaInfoLib $RepoURL $WPath/repos
        MIL_source=$WPath/repos/MediaInfoLib
    fi

    # Dependency : ZenLib
    cd $(b.get bang.working_dir)
    $(b.get bang.src_path)/bang run PrepareSource.sh -p ZenLib -r $RepoURL -w $WPath -${Target} -na -nc

    # Dependency : zlib
    cd $WPath/repos
    git clone -b "v1.2.8" https://github.com/madler/zlib

}

function _linux_compil () {

    echo
    echo "Generate the MIL directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MIL
    mkdir MediaInfo_DLL${Version}_GNU_FromSource
    cd MediaInfo_DLL${Version}_GNU_FromSource

    cp -r $MIL_source .
    mv MediaInfoLib/Project/GNU/Library/AddThisToRoot_DLL_compile.sh SO_Compile.sh
    chmod +x SO_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Dependency : zlib
    mkdir -p Shared/Source
    cp -r $WPath/repos/zlib Shared/Source
    # TODO: put MIL/Shared/Project/zlib/Compile.sh on github
    mkdir -p Shared/Project/zlib
    #echo "cd ../../Source/zlib/ ; ./configure && make" > Shared/Project/zlib/Compile.sh
    echo "cd ../../Source/zlib/ ./configure && make clean && make" > Shared/Project/zlib/Compile.sh

    echo "2: remove what isn't wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/libmediainfo.dsc GNU/libmediainfo.spec
            rm -fr Solaris
            rm -fr BCB CMake CodeBlocks Coverity Delphi Java NetBeans
            rm -fr MSCS2008 MSCS2010 MSJS MSVB MSVB2010
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr PureBasic
        cd ..
    cd ..

    echo "3: Autogen..."
    cd ZenLib/Project/GNU/Library
    sh autogen > /dev/null 2>&1
    cd ../../../../MediaInfoLib/Project/GNU/Library/
    sh autogen > /dev/null 2>&1

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_DLL${Version}_GNU_FromSource.txz MediaInfo_DLL${Version}_GNU_FromSource)
    fi

}

function _windows_compil () {

    echo
    echo "Generate the MIL directory for compilation under Windows:"
    echo "1: copy what is wanted..."

    cd $WPath/MIL
    mkdir libmediainfo${Version}_AllInclusive
    cd libmediainfo${Version}_AllInclusive

    cp -r $MIL_source .

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_windows ZenLib

    # Dependency : zlib
    cp -r $WPath/repos/zlib .

    echo "2: remove what isn't wanted..."
    cd MediaInfoLib
        rm -f .cvsignore .gitignore
        rm -fr .git
        #rm -fr Release
        rm -fr debian
        rm -fr Project/GNU Project/Solaris
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7z a -t7z -mx=9 -bd ../archives/libmediainfo${Version}_AllInclusive.7z libmediainfo${Version}_AllInclusive >/dev/null
    fi

}

function _linux_packages () {

    echo
    echo "Generate the MIL directory for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/MIL
    cp -r $MIL_source .

    echo "2: remove what isn't wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
        #rm -fr Release
        cd Project
            rm -fr Coverity PureBasic Java NetBeans BCB CMake CodeBlocks
            rm -fr Delphi MSJS MSVB MSCS2008 MSCS2010 MSVB2010
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        (XZ_OPT=-9 tar -cJ --owner=root --group=root -f ../archives/libmediainfo${Version}.txz MediaInfoLib)
    fi

}

function btask.PrepareSource.run () {

    local MIL_source

    cd $WPath

    # Clean up
    rm -fr archives
    rm -fr repos/ZenLib
    rm -fr repos/MediaInfoLib
    rm -fr repos/zlib
    rm -fr ZL
    rm -fr MIL
    mkdir MIL

    _get_source

    if [ "$Target" = "lc" ]; then
        _linux_compil
    fi
    if [ "$Target" = "wc" ]; then
        _windows_compil
    fi
    if [ "$Target" = "lp" ]; then
        _linux_packages
    fi
    if [ "$Target" = "all" ]; then
        _linux_compil
        _windows_compil
        _linux_packages
    fi

    if $CleanUp; then
        cd $WPath
        rm -fr repos
        rm -fr MIL
        rm -fr ZL
    fi

}
