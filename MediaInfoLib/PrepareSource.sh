# MediaInfoLib/Release/PrepareSource.sh
# Prepare the source of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function _get_source () {

    local RepoURL

    cd $WPath
    if ! b.path.dir? repos; then
        mkdir repos
    fi

    # Determine where are the sources of MediaInfoLib
    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else    
        if [ $(b.opt.get_opt --repo) ]; then
            RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
        else
            RepoURL="https://github.com/MediaArea/"
        fi
        getRepo MediaInfoLib $RepoURL $WPath/repos
        MIL_source=$WPath/repos/MediaInfoLib
    fi

    # Dependency : ZenLib
    if [ $(b.opt.get_opt --repo) ]; then
        RepoURL=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        RepoURL="https://github.com/MediaArea/"
    fi
    cd $(b.get bang.working_dir)
    $(b.get bang.src_path)/bang run PrepareSource.sh -p ZenLib -r $RepoURL -w $WPath -lc -wc -na -nc

    # Dependency : zlib
    getRepo zlib https://github.com/madler/ $WPath/repos

}

function _linux_compil () {

    echo
    echo "Generate the MIL archive for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MIL
    mkdir MediaInfo_DLL${Version}_GNU_FromSource
    cd MediaInfo_DLL${Version}_GNU_FromSource

    cp -r $MIL_source .
    mv MediaInfoLib/Project/GNU/Library/AddThisToRoot_DLL_compile.sh SO_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Other Dependencies
    mkdir -p Shared/Project/
    cp -r $WPath/repos/zlib Shared/Project
    # TODO
    #cp -r $curl_source Shared/Project
    # TODO: _Common files, currently an empty dir in the online archive
    mkdir Shared/Project/_Common

    echo "2: remove what isn't wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
        rm -f ToDo.txt ReadMe.txt
        rm -fr Release
        #cd Release
        #    rm -f CleanUp.bat Example.ogg ReadMe_DLL_Windows.txt
        #    rm -f Release_DLL_GNU_Prepare.bat Release_Lib_GNU_Prepare.bat
        #    rm -f Release_DLL_Windows_i386.bat Release_DLL_Windows_x64.bat
        #    rm -f Release_Source.bat UpgradeVersion.sh
        #cd ..
        rm -fr debian
        cd Project
            rm -f GNU/libmediainfo.dsc GNU/libmediainfo.spec
            rm -fr Solaris
            rm -fr BCB CMake CodeBlocks Coverity Delphi Java NetBeans
            rm -fr MSCS2008 MSCS2010 MSJS MSVB MSVB2010
            rm -fr MSVC2005 MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr PureBasic
        cd ..
        rm -fr Contrib
        cd Source
            rm -f Doc/setlocale.txt
            rm -fr Install
            rm -fr PreRelease
            rm -fr RegressionTest
            rm -fr Resource
            rm -f MediaInfoDLL/MediaInfoDLL.def
            rm -f MediaInfoDLL/MediaInfoDLL.jsl
            rm -f MediaInfoDLL/MediaInfoDLL.pas
            rm -f MediaInfoDLL/MediaInfoDLL.pb
            rm -f MediaInfoDLL/MediaInfoDLL.vb
            rm -f ThirdParty/aes-gladman/aes_amd64.asm
            rm -f ThirdParty/aes-gladman/aes.txt
            rm -f ThirdParty/aes-gladman/aes_x86_v1.asm
            rm -f ThirdParty/aes-gladman/aes_x86_v2.asm
            rm -f ThirdParty/aes-gladman/via_ace.txt
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -czf ../archives/MediaInfo_DLL${Version}_GNU_FromSource.tgz MediaInfo_DLL${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cjf ../archives/MediaInfo_DLL${Version}_GNU_FromSource.tbz MediaInfo_DLL${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJf ../archives/MediaInfo_DLL${Version}_GNU_FromSource.txz MediaInfo_DLL${Version}_GNU_FromSource)
    fi

}

function _windows_compil () {

    echo
    echo "Generate the MIL archive for compilation under Windows:"
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
        rm -fr Release
        rm -fr debian
        cd Project
            rm -fr Coverity PureBasic
            rm -f Java/ReadMe.txt NetBeans/ReadMe.txt
            rm -f MSCS2008/asp_net_web_application/Default.aspx
            rm -f MSCS2008/asp_net_web_application/Web.config
            rm -f MSCS2010/asp_net_web_application/Default.aspx
            rm -f MSCS2010/asp_net_web_application/Web.config
            rm -f MSVB2010/Example/My\ Project/Application.myapp
            rm -f MSVB2010/Example/My\ Project/Settings.settings
            rm -f MSVC2008/ShellExtension/dlldata.c
            rm -f MSVC2008/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2008/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2008/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2008/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2010/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2010/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2010/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2010/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2012/ShellExtension/dlldata.c
            rm -f MSVC2012/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2012/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2012/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2012/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2013/ShellExtension/dlldata.c
            rm -f MSVC2013/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2013/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2013/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2013/ShellExtension/MediaInfoShellExt.rgs
        cd ..
        cd Source
            rm -f ThirdParty/aes-gladman/aes_amd64.asm
            rm -f ThirdParty/aes-gladman/aes.txt
            rm -f ThirdParty/aes-gladman/aes_x86_v1.asm
            rm -f ThirdParty/aes-gladman/aes_x86_v2.asm
            rm -f ThirdParty/aes-gladman/via_ace.txt
        cd ..
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
    echo "Generate the MIL archive for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/MIL
    cp -r $MIL_source .

    echo "2: remove what isn't wanted..."
    cd MediaInfoLib
        rm -fr .cvsignore .git*
        rm -f ToDo.txt ReadMe.txt
        rm -fr Release
        cd Project
            rm -fr Coverity PureBasic
            rm -f Java/ReadMe.txt NetBeans/ReadMe.txt
            rm -f MSCS2008/asp_net_web_application/Default.aspx
            rm -f MSCS2008/asp_net_web_application/Web.config
            rm -f MSCS2010/asp_net_web_application/Default.aspx
            rm -f MSCS2010/asp_net_web_application/Web.config
            rm -f MSVB2010/Example/My\ Project/Application.myapp
            rm -f MSVB2010/Example/My\ Project/Settings.settings
            rm -f MSVC2008/ShellExtension/dlldata.c
            rm -f MSVC2008/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2008/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2008/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2008/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2010/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2010/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2010/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2010/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2012/ShellExtension/dlldata.c
            rm -f MSVC2012/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2012/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2012/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2012/ShellExtension/MediaInfoShellExt.rgs
            rm -f MSVC2013/ShellExtension/dlldata.c
            rm -f MSVC2013/ShellExtension/MediaInfo_InfoTip_Register.bat
            rm -f MSVC2013/ShellExtension/MediaInfo_InfoTip_UnRegister.bat
            rm -f MSVC2013/ShellExtension/MediaInfoShellExt_.rgs
            rm -f MSVC2013/ShellExtension/MediaInfoShellExt.rgs
        cd ..
        cd Source
            rm -f ThirdParty/aes-gladman/aes_amd64.asm
            rm -f ThirdParty/aes-gladman/aes.txt
            rm -f ThirdParty/aes-gladman/aes_x86_v1.asm
            rm -f ThirdParty/aes-gladman/aes_x86_v2.asm
            rm -f ThirdParty/aes-gladman/via_ace.txt
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MIL
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -czf ../archives/libmediainfo${Version}.tgz MediaInfoLib)
        #(BZIP=-9 tar -cjf ../archives/libmediainfo${Version}.tbz MediaInfoLib)
        (XZ_OPT=-9 tar -cJf ../archives/libmediainfo${Version}.txz MediaInfoLib)
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
    rm -fr repos/MediaInfoLib
    rm -fr repos/ZenLib
    rm -fr $WPath/MIL
    rm -fr $WPath/ZL
    mkdir $WPath/MIL

    if $LinuxCompil || $WindowsCompil || $LinuxPackages || $AllTarget; then
        _get_source
    else
        echo "Besides --project, you must specify at least one of this options:"
        echo
        echo "--linux-compil|-lc"
        echo "              Generate the archive for compilation under Linux"
        echo
        echo "--windows-compil|-wc"
        echo "              Generate the archive for compilation under Windows"
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
        rm -fr MIL
        rm -fr ZL
    fi

    unset -v WPath MIL_source
    #unset -v curl_source
    unset -v LinuxCompil WindowsCompil LinuxPackages AllTarget
    unset -v CleanUp MakeArchives

}
