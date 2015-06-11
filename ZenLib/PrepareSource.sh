# ZenLib/Release/PrepareSource.sh
# Prepare the source of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

function _get_source () {

    local RepoURL

    cd $WPath
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of ZenLib
    if [ $(b.opt.get_opt --source-path) ]; then
        ZL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else    
        if [ $(b.opt.get_opt --repo) ]; then
            RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
        else
            RepoURL="https://github.com/MediaArea/"
        fi
        getRepo ZenLib $RepoURL $WPath/repos
        ZL_source=$WPath/repos/ZenLib
    fi

}

function _linux_compil () {

    echo
    echo "Generate the ZL directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source ZenLib${Version}_compilation_under_linux

    echo "2: remove what isn't wanted..."
    cd ZenLib${Version}_compilation_under_linux
        rm -fr .cvsignore .git*
        rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec
            rm -fr Solaris
            rm -fr BCB CMake CodeBlocks Coverity
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Source/Doc Source/Example
    cd ..

}

function _windows_compil () {

    echo
    echo "Generate the ZL directory for compilation under Windows:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source ZenLib${Version}_compilation_under_windows

    echo "2: remove what isn't wanted..."
    cd ZenLib${Version}_compilation_under_windows
        rm -fr .cvsignore .git*
        rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/libzen.dsc GNU/libzen.spec
            rm -fr Solaris
            rm -fr Coverity
            rm -f BCB/CleanUp.bat
            rm -f BCB/ZenLib_Proj.groupproj
            rm -f CodeBlocks/CleanUp.bat
            rm -f MSVC2005/CleanUp.bat
            rm -f MSVC2008/CleanUp.bat
            rm -f MSVC2010/CleanUp.bat
            rm -f MSVC2012/CleanUp.bat
            rm -f MSVC2013/CleanUp.bat
        cd ..
    cd ..

}

function _linux_packages () {

    echo
    echo "Generate the ZL archive for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/ZL
    cp -r $ZL_source .

    echo "2: remove what isn't wanted..."
    cd ZenLib
        rm -fr .cvsignore .git*
        rm -fr Release
        cd Project
            rm -fr Coverity
            rm -f BCB/CleanUp.bat
            rm -f BCB/ZenLib_Proj.groupproj
            rm -f CodeBlocks/CleanUp.bat
            rm -f MSVC2005/CleanUp.bat
            rm -f MSVC2008/CleanUp.bat
            rm -f MSVC2010/CleanUp.bat
            rm -f MSVC2012/CleanUp.bat
            rm -f MSVC2013/CleanUp.bat
        cd ..
    cd ..
    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/ZL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -czf ../archives/libzen_${Version}.tgz ZenLib)
        #(BZIP=-9 tar -cjf ../archives/libzen_${Version}.tbz ZenLib)
        (XZ_OPT=-9 tar -cJf ../archives/libzen${Version}.txz ZenLib)
    fi

}

function btask.PrepareSource.run () {

    LinuxCompil=false
    if b.opt.has_flag? --linux-compil; then
        LinuxCompil=true
    fi
    WindowsCompil=false
    if b.opt.has_flag? --windows-compil; then
        WindowsCompil=true
    fi
    LinuxPackages=false
    if b.opt.has_flag? --linux-packages; then
        LinuxPackages=true
    fi
    AllTarget=false
    if b.opt.has_flag? --all; then
        AllTarget=true
    fi
    CleanUp=true
    if b.opt.has_flag? --no-cleanup; then
        CleanUp=false
    fi
    MakeArchives=true
    if b.opt.has_flag? --no-archives; then
        MakeArchives=false
    fi

    WPath=/tmp/
    if [ $(b.opt.get_opt --working-path) ]; then
        WPath="$(sanitize_arg $(b.opt.get_opt --working-path))"
        if b.path.dir? $WPath && ! b.path.writable? $WPath; then
            echo "The directory $WPath isn't writable : will use /tmp instead."
            echo
            WPath=/tmp/
        else
            # TODO: Handle exception if mkdir fail
            if ! b.path.dir? $WPath ;then
                mkdir $WPath
            fi
        fi
    fi
    cd $WPath

    # Clean up
    rm -fr archives
    rm -fr repos/ZenLib
    rm -fr $WPath/ZL
    mkdir $WPath/ZL

    if $LinuxCompil || $WindowsCompil || $LinuxPackages || $AllTarget; then
        _get_source
    else
        echo "Besides --project, you must specify at least one of this options:"
        echo
        echo "--linux-compil|-lc"
        echo "              Generate the directory for compilation under Linux"
        echo
        echo "--windows-compil|-wc"
        echo "              Generate the directory for compilation under Windows"
        echo
        echo "--linux-packages|-lp|--linux-package"
        echo "              Generate the archive for Linux packages creation"
        echo
        echo "--all|-a"
        echo "              Prepare all the targets for this project"
    fi

    if $LinuxCompil; then
        _linux_compil
    fi
    if $WindowsCompil; then
        _windows_compil
    fi
    if $LinuxPackages; then
        _linux_packages
    fi
    if $AllTarget; then
        _linux_compil
        _windows_compil
        _linux_packages
    fi
    
    if $CleanUp; then
        cd $WPath
        rm -fr repos
        rm -fr ZL
    fi

    unset -v WPath ZL_source
    unset -v LinuxCompil WindowsCompil LinuxPackages AllTarget
    unset -v CleanUp MakeArchives

}
