# MediaInfo/Release/PrepareSource.sh
# Prepare the source of MediaInfo

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

    # Determine where are the sources of MediaInfo
    if [ $(b.opt.get_opt --source-path) ]; then
        MI_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo MediaInfo $RepoURL $WPath/repos
        MI_source=$WPath/repos/MediaInfo
    fi

    # Dependency : MediaInfoLib (will also bring ZenLib and zlib)
    cd $(b.get bang.working_dir)
    $(b.get bang.src_path)/bang run PrepareSource.sh -p MediaInfoLib -r $RepoURL -w $WPath -a -na -nc

    # Dependency : WxWidgets
    #getRepo zlib https://github.com/madler/ $WPath/repos

}

function _linux_gui_compil () {

    echo "Generate the MI GUI directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir MediaInfo_GUI${Version}_GNU_FromSource
    cd MediaInfo_GUI${Version}_GNU_FromSource

    cp -r $MI_source .
    mv MediaInfo/Project/GNU/GUI/AddThisToRoot_GUI_compile.sh GUI_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/MediaInfo_DLL_GNU_FromSource MediaInfoLib

    # Other Dependencies
    mkdir -p Shared/Project/
    cp -r $WPath/repos/zlib Shared/Project
    # TODO
    # WxWidgets
    # TODO: _Common files, currently an empty dir in the online archive
    mkdir Shared/Project/_Common

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_CLI.txt
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/CLI
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Contrib
        cd Source
            # Since the linux archive is also for mac
            #rm -fr GUI/Cocoa
            #rm -fr GUI/Qt
            rm -fr GUI/VCL
            rm -fr GUI/VCL_New
            rm -fr Install
            rm -fr PreRelease
            rm -fr Resource/Plugin
            #rm -f Resource/Image/MediaInfo.ico
            #rm -f Resource/Image/MediaInfo.svg
            #rm -f Resource/Image/MediaInfo_TinyOnly.ico
            #rm -f Resource/Image/Menu/Debug.ico
            #rm -f Resource/Image/Menu/File_Export.ico
            #rm -f Resource/Image/Menu/File_Open_Directory.ico
            #rm -f Resource/Image/Menu/File_Open_Directory.xpm
            #rm -f Resource/Image/Menu/File_Open_File.ico
            #rm -f Resource/Image/Menu/File_Open_File.xpm
            #rm -f Resource/Image/Menu/Help_About.ico
            #rm -f Resource/Image/Menu/Help_About.xpm
            #rm -f Resource/Image/Menu/K20/File_Export.png
            #rm -f Resource/Image/Menu/K20/File_Export.svg
            #rm -f Resource/Image/Menu/K20/File_Open_Directory.ico
            #rm -f Resource/Image/Menu/K20/File_Open_Directory.png
            #rm -f Resource/Image/Menu/K20/File_Open_Directory.svg
            #rm -f Resource/Image/Menu/K20/File_Open_File2.png
            #rm -f Resource/Image/Menu/K20/File_Open_File.ico
            #rm -f Resource/Image/Menu/K20/File_Open_File.png
            #rm -f Resource/Image/Menu/K20/File_Open_File.svg
            #rm -f Resource/Image/Menu/K20/File_Save.svg
            #rm -f Resource/Image/Menu/K20/Help_About.ico
            #rm -f Resource/Image/Menu/K20/Help_About.png
            #rm -f Resource/Image/Menu/K20/Help_About.svg
            #rm -f Resource/Image/Menu/K20/Options_Prefs.png
            #rm -f Resource/Image/Menu/K20/Options_Prefs.svg
            #rm -f Resource/Image/Menu/K20/View2.svg
            #rm -f Resource/Image/Menu/K20/View.png
            #rm -f Resource/Image/Menu/K20/View.svg
            #rm -f Resource/Image/Menu/Language.ico
            #rm -f Resource/Image/Menu/Options_Prefs.ico
            #rm -f Resource/Image/Menu/View.ico
            #rm -f Resource/Image/Menu/View_System.ico
            #rm -f Resource/Image/Windows_Finish.bmp
            rm -f Resource/Language.csv
            rm -f Resource/Resources.qrc
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tgz MediaInfo_GUI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tbz MediaInfo_GUI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_GUI${Version}_GNU_FromSource.txz MediaInfo_GUI${Version}_GNU_FromSource)
    fi

}

function _linux_cli_compil () {

    echo
    echo "Generate the MI CLI directory for compilation under Linux:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir MediaInfo_CLI${Version}_GNU_FromSource
    cd MediaInfo_CLI${Version}_GNU_FromSource

    cp -r $MI_source .
    mv MediaInfo/Project/GNU/CLI/AddThisToRoot_CLI_compile.sh CLI_Compile.sh

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_linux ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/MediaInfo_DLL_GNU_FromSource MediaInfoLib

    # Other Dependencies
    mkdir -p Shared/Project/
    cp -r $WPath/repos/zlib Shared/Project
    # TODO: _Common files, currently an empty dir in the online archive
    mkdir Shared/Project/_Common

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -f History_GUI.txt
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/GUI
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Contrib
        cd Source
            rm -fr Source/GUI/
            rm -fr Source/Install
            rm -fr Source/PreRelease
            rm -fr Source/Resource/
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tgz MediaInfo_CLI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tbz MediaInfo_CLI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f ../archives/MediaInfo_CLI${Version}_GNU_FromSource.txz MediaInfo_CLI${Version}_GNU_FromSource)
    fi

}

function _windows_compil () {

    echo
    echo "Generate the MI directory for compilation under Windows:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    mkdir mediainfo${Version}_AllInclusive
    cd mediainfo${Version}_AllInclusive

    cp -r $MI_source .

    # Dependency : ZenLib
    cp -r $WPath/ZL/ZenLib_compilation_under_windows ZenLib

    # Dependency : MediaInfoLib
    cp -r $WPath/MIL/libmediainfo_AllInclusive MediaInfoLib

    # Dependency : zlib
    cp -r $WPath/repos/zlib .

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -f .cvsignore .gitignore
        rm -fr .git
        #rm -fr Release
        rm -fr debian
        cd Project
            rm -fr Mac Solaris OBS
        cd ..
        rm -fr Source/GUI/Cocoa/
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        7z a -t7z -mx=9 -bd ../archives/mediainfo${Version}_AllInclusive.7z mediainfo${Version}_AllInclusive >/dev/null
    fi

}

function _linux_packages () {

    echo
    echo "Generate the MI directory for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    cp -r $MI_source .

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        #rm -fr Release
        cd Project
            rm -fr BCB QMake CodeBlocks
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
            rm -fr Mac Solaris OBS
        cd ..
        rm -fr Source/GUI/Cocoa/
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -cz --owner=root --group=root -f ../archives/mediainfo${Version}.tgz MediaInfo)
        #(BZIP=-9 tar -cj --owner=root --group=root -f ../archives/mediainfo${Version}.tbz MediaInfo)
        (XZ_OPT=-9 tar -cJ --owner=root --group=root -f ../archives/mediainfo${Version}.txz MediaInfo)
    fi

}

function btask.PrepareSource.run () {

    local MI_source

    cd $WPath

    # Clean up
    rm -fr archives
    rm -fr repos
    mkdir repos
    rm -fr ZL
    rm -fr MIL
    rm -fr MI
    mkdir MI

    if $LinuxCompil || $WindowsCompil || $LinuxPackages || $AllTarget; then
        _get_source
    else
        echo "Besides --project, you must specify at least one of this options:"
        echo
        echo "--linux-compil|-lc"
        echo "              Generate the MI directory for compilation under Linux"
        echo
        echo "--windows-compil|-wc"
        echo "              Generate the MI directory for compilation under Windows"
        echo
        echo "--linux-packages|-lp|--linux-package"
        echo "              Generate the MI directory for Linux packages creation"
        echo
        echo "--all|-a"
        echo "              Prepare all the targets for this project"
    fi

    if $LinuxCompil; then
        _linux_gui_compil
        _linux_cli_compil
    fi
    if $WindowsCompil; then
        _windows_compil
    fi
    if $LinuxPackages; then
        _linux_packages
    fi
    if $AllTarget; then
        _linux_gui_compil
        _linux_cli_compil
        _windows_compil
        _linux_packages
    fi
    
    if $CleanUp; then
        cd $WPath
        rm -fr repos
        rm -fr ZL
        rm -fr MIL
    fi

}
