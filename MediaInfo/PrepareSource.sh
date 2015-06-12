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

    echo "Generate the MI GUI archive for compilation under Linux:"
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
        rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/CLI
            rm -fr Solaris Mac
            rm -fr BCB QMake CodeBlocks OBS
            rm -fr MSVC2008 MSVC2010 MSVC2012 MSVC2013
        cd ..
        rm -fr Contrib
        cd Source
            rm -fr Source/GUI/Cocoa
            rm -fr Source/GUI/Qt
            rm -fr Source/GUI/VCL
            rm -fr Source/GUI/VCL_New
            rm -fr Source/Install
            rm -fr Source/PreRelease
            rm -fr Source/Resource/Plugin
            rm -f Source/Resource/Image/MediaInfo.ico
            rm -f Source/Resource/Image/MediaInfo.svg
            rm -f Source/Resource/Image/MediaInfo_TinyOnly.ico
            rm -f Source/Resource/Image/Menu/Debug.ico
            rm -f Source/Resource/Image/Menu/File_Export.ico
            rm -f Source/Resource/Image/Menu/File_Open_Directory.ico
            rm -f Source/Resource/Image/Menu/File_Open_Directory.xpm
            rm -f Source/Resource/Image/Menu/File_Open_File.ico
            rm -f Source/Resource/Image/Menu/File_Open_File.xpm
            rm -f Source/Resource/Image/Menu/Help_About.ico
            rm -f Source/Resource/Image/Menu/Help_About.xpm
            rm -f Source/Resource/Image/Menu/K20/File_Export.png
            rm -f Source/Resource/Image/Menu/K20/File_Export.svg
            rm -f Source/Resource/Image/Menu/K20/File_Open_Directory.ico
            rm -f Source/Resource/Image/Menu/K20/File_Open_Directory.png
            rm -f Source/Resource/Image/Menu/K20/File_Open_Directory.svg
            rm -f Source/Resource/Image/Menu/K20/File_Open_File2.png
            rm -f Source/Resource/Image/Menu/K20/File_Open_File.ico
            rm -f Source/Resource/Image/Menu/K20/File_Open_File.png
            rm -f Source/Resource/Image/Menu/K20/File_Open_File.svg
            rm -f Source/Resource/Image/Menu/K20/File_Save.svg
            rm -f Source/Resource/Image/Menu/K20/Help_About.ico
            rm -f Source/Resource/Image/Menu/K20/Help_About.png
            rm -f Source/Resource/Image/Menu/K20/Help_About.svg
            rm -f Source/Resource/Image/Menu/K20/Options_Prefs.png
            rm -f Source/Resource/Image/Menu/K20/Options_Prefs.svg
            rm -f Source/Resource/Image/Menu/K20/View2.svg
            rm -f Source/Resource/Image/Menu/K20/View.png
            rm -f Source/Resource/Image/Menu/K20/View.svg
            rm -f Source/Resource/Image/Menu/Language.ico
            rm -f Source/Resource/Image/Menu/Options_Prefs.ico
            rm -f Source/Resource/Image/Menu/View.ico
            rm -f Source/Resource/Image/Menu/View_System.ico
            rm -f Source/Resource/Image/Windows_Finish.bmp
            rm -f Source/Resource/Language.csv
            rm -f Source/Resource/Resources.qrc
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -czf ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tgz MediaInfo_GUI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cjf ../archives/MediaInfo_GUI${Version}_GNU_FromSource.tbz MediaInfo_GUI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJf ../archives/MediaInfo_GUI${Version}_GNU_FromSource.txz MediaInfo_GUI${Version}_GNU_FromSource)
    fi

}

function _linux_cli_compil () {

    echo
    echo "Generate the MI CLI archive for compilation under Linux:"
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
        rm -fr Release
        rm -fr debian
        cd Project
            rm -f GNU/mediainfo.dsc GNU/mediainfo.spec
            rm -fr GNU/GUI
            rm -fr Solaris Mac
            rm -fr BCB QMake CodeBlocks OBS
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
        #(GZIP=-9 tar -czf ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tgz MediaInfo_CLI${Version}_GNU_FromSource)
        #(BZIP=-9 tar -cjf ../archives/MediaInfo_CLI${Version}_GNU_FromSource.tbz MediaInfo_CLI${Version}_GNU_FromSource)
        (XZ_OPT=-9e tar -cJf ../archives/MediaInfo_CLI${Version}_GNU_FromSource.txz MediaInfo_CLI${Version}_GNU_FromSource)
    fi

}

function _windows_compil () {

    echo
    echo "Generate the MI archive for compilation under Windows:"
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
        rm -fr Release
        rm -fr debian
        cd Project
            rm -fr BCB/WxWidgets/Debug_Build
            rm -f BCB/GUI/MediaInfo_GUI.cpp
            rm -f BCB/GUI_New/GUI_New.cpp
            rm -f BCB/GUI_New/GUI_New.res
            rm -f BCB/PreRelease/PreRelease.cpp
            rm -f BCB/PreRelease/PreRelease.res
            rm -fr Mac OBS
        cd ..
        cd Source
            rm -fr GUI/Cocoa/MediaInfo.xcodeproj
            rm -f GUI/Cocoa/AboutWindowController.m
            rm -f GUI/Cocoa/AppController.m
            rm -f GUI/Cocoa/ar.lproj/About.strings
            rm -f GUI/Cocoa/ar.lproj/Localizable.strings
            rm -f GUI/Cocoa/ar.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ar.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ar.lproj/Preferences.strings
            rm -f GUI/Cocoa/ca.lproj/About.strings
            rm -f GUI/Cocoa/ca.lproj/Localizable.strings
            rm -f GUI/Cocoa/ca.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ca.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ca.lproj/Preferences.strings
            rm -f GUI/Cocoa/cs.lproj/About.strings
            rm -f GUI/Cocoa/cs.lproj/Localizable.strings
            rm -f GUI/Cocoa/cs.lproj/MainMenu.strings
            rm -f GUI/Cocoa/cs.lproj/MyWindow.strings
            rm -f GUI/Cocoa/cs.lproj/Preferences.strings
            rm -f GUI/Cocoa/da.lproj/About.strings
            rm -f GUI/Cocoa/da.lproj/Localizable.strings
            rm -f GUI/Cocoa/da.lproj/MainMenu.strings
            rm -f GUI/Cocoa/da.lproj/MyWindow.strings
            rm -f GUI/Cocoa/da.lproj/Preferences.strings
            rm -f GUI/Cocoa/de.lproj/About.strings
            rm -f GUI/Cocoa/de.lproj/Localizable.strings
            rm -f GUI/Cocoa/de.lproj/MainMenu.strings
            rm -f GUI/Cocoa/de.lproj/MyWindow.strings
            rm -f GUI/Cocoa/de.lproj/Preferences.strings
            rm -f GUI/Cocoa/easyStreamsTableDelegate.m
            rm -f GUI/Cocoa/el.lproj/About.strings
            rm -f GUI/Cocoa/el.lproj/Localizable.strings
            rm -f GUI/Cocoa/el.lproj/MainMenu.strings
            rm -f GUI/Cocoa/el.lproj/MyWindow.strings
            rm -f GUI/Cocoa/el.lproj/Preferences.strings
            rm -f GUI/Cocoa/English.lproj/About.strings
            rm -f GUI/Cocoa/English.lproj/InfoPlist.strings
            rm -f GUI/Cocoa/English.lproj/Localizable.strings
            rm -f GUI/Cocoa/English.lproj/MainMenu.strings
            rm -f GUI/Cocoa/English.lproj/MyWindow.strings
            rm -f GUI/Cocoa/English.lproj/Preferences.strings
            rm -f GUI/Cocoa/es.lproj/About.strings
            rm -f GUI/Cocoa/es.lproj/Localizable.strings
            rm -f GUI/Cocoa/es.lproj/MainMenu.strings
            rm -f GUI/Cocoa/es.lproj/MyWindow.strings
            rm -f GUI/Cocoa/es.lproj/Preferences.strings
            rm -f GUI/Cocoa/fr.lproj/About.strings
            rm -f GUI/Cocoa/fr.lproj/Localizable.strings
            rm -f GUI/Cocoa/fr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/fr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/fr.lproj/Preferences.strings
            rm -f GUI/Cocoa/hr.lproj/About.strings
            rm -f GUI/Cocoa/hr.lproj/Localizable.strings
            rm -f GUI/Cocoa/hr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/hr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/hr.lproj/Preferences.strings
            rm -f GUI/Cocoa/hu.lproj/About.strings
            rm -f GUI/Cocoa/hu.lproj/Localizable.strings
            rm -f GUI/Cocoa/hu.lproj/MainMenu.strings
            rm -f GUI/Cocoa/hu.lproj/MyWindow.strings
            rm -f GUI/Cocoa/hu.lproj/Preferences.strings
            rm -f GUI/Cocoa/HyperlinkButton.m
            rm -f GUI/Cocoa/_i18n/create_lang_strings.pl
            rm -f GUI/Cocoa/_i18n/gtranslate.py
            rm -f GUI/Cocoa/_i18n/README
            rm -f GUI/Cocoa/_i18n/stringsdb.txt
            rm -f GUI/Cocoa/_i18n/_update_file_in_stringsdb.pl
            rm -f GUI/Cocoa/it.lproj/About.strings
            rm -f GUI/Cocoa/it.lproj/Localizable.strings
            rm -f GUI/Cocoa/it.lproj/MainMenu.strings
            rm -f GUI/Cocoa/it.lproj/MyWindow.strings
            rm -f GUI/Cocoa/it.lproj/Preferences.strings
            rm -f GUI/Cocoa/ja.lproj/About.strings
            rm -f GUI/Cocoa/ja.lproj/Localizable.strings
            rm -f GUI/Cocoa/ja.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ja.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ja.lproj/Preferences.strings
            rm -f GUI/Cocoa/ko.lproj/About.strings
            rm -f GUI/Cocoa/ko.lproj/Localizable.strings
            rm -f GUI/Cocoa/ko.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ko.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ko.lproj/Preferences.strings
            rm -f GUI/Cocoa/Language/Edit.ar.strings
            rm -f GUI/Cocoa/Language/Edit.ca.strings
            rm -f GUI/Cocoa/Language/Edit.cs.strings
            rm -f GUI/Cocoa/Language/Edit.da.strings
            rm -f GUI/Cocoa/Language/Edit.de.strings
            rm -f GUI/Cocoa/Language/Edit.el.strings
            rm -f GUI/Cocoa/Language/Edit.English.strings
            rm -f GUI/Cocoa/Language/Edit.es.strings
            rm -f GUI/Cocoa/Language/Edit.fi.strings
            rm -f GUI/Cocoa/Language/Edit.fr.strings
            rm -f GUI/Cocoa/Language/Edit.he.strings
            rm -f GUI/Cocoa/Language/Edit.hr.strings
            rm -f GUI/Cocoa/Language/Edit.hu.strings
            rm -f GUI/Cocoa/Language/Edit.it.strings
            rm -f GUI/Cocoa/Language/Edit.ja.strings
            rm -f GUI/Cocoa/Language/Edit.ko.strings
            rm -f GUI/Cocoa/Language/Edit.nl.strings
            rm -f GUI/Cocoa/Language/Edit.no.strings
            rm -f GUI/Cocoa/Language/Edit.pl.strings
            rm -f GUI/Cocoa/Language/Edit.pt-PT.strings
            rm -f GUI/Cocoa/Language/Edit.pt.strings
            rm -f GUI/Cocoa/Language/Edit.ro.strings
            rm -f GUI/Cocoa/Language/Edit.ru.strings
            rm -f GUI/Cocoa/Language/Edit.sk.strings
            rm -f GUI/Cocoa/Language/Edit.sv.strings
            rm -f GUI/Cocoa/Language/Edit.th.strings
            rm -f GUI/Cocoa/Language/Edit.tr.strings
            rm -f GUI/Cocoa/Language/Edit.uk.strings
            rm -f GUI/Cocoa/Language/Edit.zh-Hans.strings
            rm -f GUI/Cocoa/Language/Edit.zh-Hant.strings
            rm -f GUI/Cocoa/Language/en.txt
            rm -f GUI/Cocoa/Language/Localizable.en.strings
            rm -f GUI/Cocoa/Language/Localizable.fr.strings
            rm -f GUI/Cocoa/Language/Localizable.ru.strings
            rm -f GUI/Cocoa/Language/Main.ar.strings
            rm -f GUI/Cocoa/Language/Main.bg.strings
            rm -f GUI/Cocoa/Language/Main.ca.strings
            rm -f GUI/Cocoa/Language/Main.cs.strings
            rm -f GUI/Cocoa/Language/Main.da.strings
            rm -f GUI/Cocoa/Language/Main.de.strings
            rm -f GUI/Cocoa/Language/Main.el.strings
            rm -f GUI/Cocoa/Language/Main.es.strings
            rm -f GUI/Cocoa/Language/Main.fr.strings
            rm -f GUI/Cocoa/Language/Main.hu.strings
            rm -f GUI/Cocoa/Language/Main.it.strings
            rm -f GUI/Cocoa/Language/Main.ja.strings
            rm -f GUI/Cocoa/Language/Main.ka.strings
            rm -f GUI/Cocoa/Language/Main.ko.strings
            rm -f GUI/Cocoa/Language/Main.nl.strings
            rm -f GUI/Cocoa/Language/Main.pl.strings
            rm -f GUI/Cocoa/Language/Main.pt-BR.strings
            rm -f GUI/Cocoa/Language/Main.pt-PT.strings
            rm -f GUI/Cocoa/Language/Main.pt.strings
            rm -f GUI/Cocoa/Language/Main.ro.strings
            rm -f GUI/Cocoa/Language/Main.ru.orig.strings
            rm -f GUI/Cocoa/Language/Main.ru.strings
            rm -f GUI/Cocoa/Language/Main.sk.strings
            rm -f GUI/Cocoa/Language/Main.sv.strings
            rm -f GUI/Cocoa/Language/Main.th.strings
            rm -f GUI/Cocoa/Language/Main.tr.strings
            rm -f GUI/Cocoa/Language/Main.uk.strings
            rm -f GUI/Cocoa/Language/Main.zh-CN.strings
            rm -f GUI/Cocoa/Language/Main.zh-Hans.strings
            rm -f GUI/Cocoa/Language/Main.zh-Hant.strings
            rm -f GUI/Cocoa/Language/Main.zh-TW.strings
            rm -f GUI/Cocoa/Language/ru.txt
            rm -f GUI/Cocoa/main.m
            rm -f GUI/Cocoa/MediaInfo.entitlements
            rm -f GUI/Cocoa/MediaInfoExporter.m
            rm -f GUI/Cocoa/mediainfo.icns
            rm -f GUI/Cocoa/MediaInfo-Info.plist
            rm -f GUI/Cocoa/MediaInfo_Prefix.pch
            rm -f GUI/Cocoa/MyWindowController.m
            rm -f GUI/Cocoa/nl.lproj/About.strings
            rm -f GUI/Cocoa/nl.lproj/Localizable.strings
            rm -f GUI/Cocoa/nl.lproj/MainMenu.strings
            rm -f GUI/Cocoa/nl.lproj/MyWindow.strings
            rm -f GUI/Cocoa/nl.lproj/Preferences.strings
            rm -f GUI/Cocoa/NSString+wchar.m
            rm -f GUI/Cocoa/oMediaInfoList.mm
            rm -f GUI/Cocoa/pl.lproj/About.strings
            rm -f GUI/Cocoa/pl.lproj/Localizable.strings
            rm -f GUI/Cocoa/pl.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pl.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pl.lproj/Preferences.strings
            rm -f GUI/Cocoa/PreferencesWindowController.m
            rm -f GUI/Cocoa/pt.lproj/About.strings
            rm -f GUI/Cocoa/pt.lproj/Localizable.strings
            rm -f GUI/Cocoa/pt.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pt.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pt.lproj/Preferences.strings
            rm -f GUI/Cocoa/pt-PT.lproj/About.strings
            rm -f GUI/Cocoa/pt-PT.lproj/Localizable.strings
            rm -f GUI/Cocoa/pt-PT.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pt-PT.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pt-PT.lproj/Preferences.strings
            rm -f GUI/Cocoa/ro.lproj/About.strings
            rm -f GUI/Cocoa/ro.lproj/Localizable.strings
            rm -f GUI/Cocoa/ro.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ro.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ro.lproj/Preferences.strings
            rm -f GUI/Cocoa/ru.lproj/About.strings
            rm -f GUI/Cocoa/ru.lproj/Localizable.strings
            rm -f GUI/Cocoa/ru.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ru.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ru.lproj/Preferences.strings
            rm -f GUI/Cocoa/sk.lproj/About.strings
            rm -f GUI/Cocoa/sk.lproj/Localizable.strings
            rm -f GUI/Cocoa/sk.lproj/MainMenu.strings
            rm -f GUI/Cocoa/sk.lproj/MyWindow.strings
            rm -f GUI/Cocoa/sk.lproj/Preferences.strings
            rm -f GUI/Cocoa/sv.lproj/About.strings
            rm -f GUI/Cocoa/sv.lproj/Localizable.strings
            rm -f GUI/Cocoa/sv.lproj/MainMenu.strings
            rm -f GUI/Cocoa/sv.lproj/MyWindow.strings
            rm -f GUI/Cocoa/sv.lproj/Preferences.strings
            rm -f GUI/Cocoa/TreeOutlineDelegate.m
            rm -f GUI/Cocoa/TreeOutline.m
            rm -f GUI/Cocoa/tr.lproj/About.strings
            rm -f GUI/Cocoa/tr.lproj/Localizable.strings
            rm -f GUI/Cocoa/tr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/tr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/tr.lproj/Preferences.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/About.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/Localizable.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/MainMenu.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/MyWindow.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/Preferences.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/About.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/Localizable.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/MainMenu.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/MyWindow.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/Preferences.strings
            rm -f GUI/Qt/sheet system.xmi
            rm -f Install/MediaInfo_Extensions.nsh
            rm -f Resource/Image/Windows_Finish.bmp
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
    echo "Generate the MI archive for Linux packages creation:"
    echo "1: copy what is wanted..."

    cd $WPath/MI
    cp -r $MI_source .

    echo "2: remove what isn't wanted..."
    cd MediaInfo
        rm -fr .cvsignore .git*
        rm -fr Release
        cd Project
            rm -fr BCB/WxWidgets/Debug_Build
            rm -f BCB/GUI/MediaInfo_GUI.cpp
            rm -f BCB/GUI_New/GUI_New.cpp
            rm -f BCB/GUI_New/GUI_New.res
            rm -f BCB/PreRelease/PreRelease.cpp
            rm -f BCB/PreRelease/PreRelease.res
            rm -fr Mac OBS
        cd ..
        cd Source
            rm -fr GUI/Cocoa/MediaInfo.xcodeproj
            rm -f GUI/Cocoa/AboutWindowController.m
            rm -f GUI/Cocoa/AppController.m
            rm -f GUI/Cocoa/ar.lproj/About.strings
            rm -f GUI/Cocoa/ar.lproj/Localizable.strings
            rm -f GUI/Cocoa/ar.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ar.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ar.lproj/Preferences.strings
            rm -f GUI/Cocoa/ca.lproj/About.strings
            rm -f GUI/Cocoa/ca.lproj/Localizable.strings
            rm -f GUI/Cocoa/ca.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ca.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ca.lproj/Preferences.strings
            rm -f GUI/Cocoa/cs.lproj/About.strings
            rm -f GUI/Cocoa/cs.lproj/Localizable.strings
            rm -f GUI/Cocoa/cs.lproj/MainMenu.strings
            rm -f GUI/Cocoa/cs.lproj/MyWindow.strings
            rm -f GUI/Cocoa/cs.lproj/Preferences.strings
            rm -f GUI/Cocoa/da.lproj/About.strings
            rm -f GUI/Cocoa/da.lproj/Localizable.strings
            rm -f GUI/Cocoa/da.lproj/MainMenu.strings
            rm -f GUI/Cocoa/da.lproj/MyWindow.strings
            rm -f GUI/Cocoa/da.lproj/Preferences.strings
            rm -f GUI/Cocoa/de.lproj/About.strings
            rm -f GUI/Cocoa/de.lproj/Localizable.strings
            rm -f GUI/Cocoa/de.lproj/MainMenu.strings
            rm -f GUI/Cocoa/de.lproj/MyWindow.strings
            rm -f GUI/Cocoa/de.lproj/Preferences.strings
            rm -f GUI/Cocoa/easyStreamsTableDelegate.m
            rm -f GUI/Cocoa/el.lproj/About.strings
            rm -f GUI/Cocoa/el.lproj/Localizable.strings
            rm -f GUI/Cocoa/el.lproj/MainMenu.strings
            rm -f GUI/Cocoa/el.lproj/MyWindow.strings
            rm -f GUI/Cocoa/el.lproj/Preferences.strings
            rm -f GUI/Cocoa/English.lproj/About.strings
            rm -f GUI/Cocoa/English.lproj/InfoPlist.strings
            rm -f GUI/Cocoa/English.lproj/Localizable.strings
            rm -f GUI/Cocoa/English.lproj/MainMenu.strings
            rm -f GUI/Cocoa/English.lproj/MyWindow.strings
            rm -f GUI/Cocoa/English.lproj/Preferences.strings
            rm -f GUI/Cocoa/es.lproj/About.strings
            rm -f GUI/Cocoa/es.lproj/Localizable.strings
            rm -f GUI/Cocoa/es.lproj/MainMenu.strings
            rm -f GUI/Cocoa/es.lproj/MyWindow.strings
            rm -f GUI/Cocoa/es.lproj/Preferences.strings
            rm -f GUI/Cocoa/fr.lproj/About.strings
            rm -f GUI/Cocoa/fr.lproj/Localizable.strings
            rm -f GUI/Cocoa/fr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/fr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/fr.lproj/Preferences.strings
            rm -f GUI/Cocoa/hr.lproj/About.strings
            rm -f GUI/Cocoa/hr.lproj/Localizable.strings
            rm -f GUI/Cocoa/hr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/hr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/hr.lproj/Preferences.strings
            rm -f GUI/Cocoa/hu.lproj/About.strings
            rm -f GUI/Cocoa/hu.lproj/Localizable.strings
            rm -f GUI/Cocoa/hu.lproj/MainMenu.strings
            rm -f GUI/Cocoa/hu.lproj/MyWindow.strings
            rm -f GUI/Cocoa/hu.lproj/Preferences.strings
            rm -f GUI/Cocoa/HyperlinkButton.m
            rm -f GUI/Cocoa/_i18n/create_lang_strings.pl
            rm -f GUI/Cocoa/_i18n/gtranslate.py
            rm -f GUI/Cocoa/_i18n/README
            rm -f GUI/Cocoa/_i18n/stringsdb.txt
            rm -f GUI/Cocoa/_i18n/_update_file_in_stringsdb.pl
            rm -f GUI/Cocoa/it.lproj/About.strings
            rm -f GUI/Cocoa/it.lproj/Localizable.strings
            rm -f GUI/Cocoa/it.lproj/MainMenu.strings
            rm -f GUI/Cocoa/it.lproj/MyWindow.strings
            rm -f GUI/Cocoa/it.lproj/Preferences.strings
            rm -f GUI/Cocoa/ja.lproj/About.strings
            rm -f GUI/Cocoa/ja.lproj/Localizable.strings
            rm -f GUI/Cocoa/ja.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ja.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ja.lproj/Preferences.strings
            rm -f GUI/Cocoa/ko.lproj/About.strings
            rm -f GUI/Cocoa/ko.lproj/Localizable.strings
            rm -f GUI/Cocoa/ko.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ko.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ko.lproj/Preferences.strings
            rm -f GUI/Cocoa/Language/Edit.ar.strings
            rm -f GUI/Cocoa/Language/Edit.ca.strings
            rm -f GUI/Cocoa/Language/Edit.cs.strings
            rm -f GUI/Cocoa/Language/Edit.da.strings
            rm -f GUI/Cocoa/Language/Edit.de.strings
            rm -f GUI/Cocoa/Language/Edit.el.strings
            rm -f GUI/Cocoa/Language/Edit.English.strings
            rm -f GUI/Cocoa/Language/Edit.es.strings
            rm -f GUI/Cocoa/Language/Edit.fi.strings
            rm -f GUI/Cocoa/Language/Edit.fr.strings
            rm -f GUI/Cocoa/Language/Edit.he.strings
            rm -f GUI/Cocoa/Language/Edit.hr.strings
            rm -f GUI/Cocoa/Language/Edit.hu.strings
            rm -f GUI/Cocoa/Language/Edit.it.strings
            rm -f GUI/Cocoa/Language/Edit.ja.strings
            rm -f GUI/Cocoa/Language/Edit.ko.strings
            rm -f GUI/Cocoa/Language/Edit.nl.strings
            rm -f GUI/Cocoa/Language/Edit.no.strings
            rm -f GUI/Cocoa/Language/Edit.pl.strings
            rm -f GUI/Cocoa/Language/Edit.pt-PT.strings
            rm -f GUI/Cocoa/Language/Edit.pt.strings
            rm -f GUI/Cocoa/Language/Edit.ro.strings
            rm -f GUI/Cocoa/Language/Edit.ru.strings
            rm -f GUI/Cocoa/Language/Edit.sk.strings
            rm -f GUI/Cocoa/Language/Edit.sv.strings
            rm -f GUI/Cocoa/Language/Edit.th.strings
            rm -f GUI/Cocoa/Language/Edit.tr.strings
            rm -f GUI/Cocoa/Language/Edit.uk.strings
            rm -f GUI/Cocoa/Language/Edit.zh-Hans.strings
            rm -f GUI/Cocoa/Language/Edit.zh-Hant.strings
            rm -f GUI/Cocoa/Language/en.txt
            rm -f GUI/Cocoa/Language/Localizable.en.strings
            rm -f GUI/Cocoa/Language/Localizable.fr.strings
            rm -f GUI/Cocoa/Language/Localizable.ru.strings
            rm -f GUI/Cocoa/Language/Main.ar.strings
            rm -f GUI/Cocoa/Language/Main.bg.strings
            rm -f GUI/Cocoa/Language/Main.ca.strings
            rm -f GUI/Cocoa/Language/Main.cs.strings
            rm -f GUI/Cocoa/Language/Main.da.strings
            rm -f GUI/Cocoa/Language/Main.de.strings
            rm -f GUI/Cocoa/Language/Main.el.strings
            rm -f GUI/Cocoa/Language/Main.es.strings
            rm -f GUI/Cocoa/Language/Main.fr.strings
            rm -f GUI/Cocoa/Language/Main.hu.strings
            rm -f GUI/Cocoa/Language/Main.it.strings
            rm -f GUI/Cocoa/Language/Main.ja.strings
            rm -f GUI/Cocoa/Language/Main.ka.strings
            rm -f GUI/Cocoa/Language/Main.ko.strings
            rm -f GUI/Cocoa/Language/Main.nl.strings
            rm -f GUI/Cocoa/Language/Main.pl.strings
            rm -f GUI/Cocoa/Language/Main.pt-BR.strings
            rm -f GUI/Cocoa/Language/Main.pt-PT.strings
            rm -f GUI/Cocoa/Language/Main.pt.strings
            rm -f GUI/Cocoa/Language/Main.ro.strings
            rm -f GUI/Cocoa/Language/Main.ru.orig.strings
            rm -f GUI/Cocoa/Language/Main.ru.strings
            rm -f GUI/Cocoa/Language/Main.sk.strings
            rm -f GUI/Cocoa/Language/Main.sv.strings
            rm -f GUI/Cocoa/Language/Main.th.strings
            rm -f GUI/Cocoa/Language/Main.tr.strings
            rm -f GUI/Cocoa/Language/Main.uk.strings
            rm -f GUI/Cocoa/Language/Main.zh-CN.strings
            rm -f GUI/Cocoa/Language/Main.zh-Hans.strings
            rm -f GUI/Cocoa/Language/Main.zh-Hant.strings
            rm -f GUI/Cocoa/Language/Main.zh-TW.strings
            rm -f GUI/Cocoa/Language/ru.txt
            rm -f GUI/Cocoa/main.m
            rm -f GUI/Cocoa/MediaInfo.entitlements
            rm -f GUI/Cocoa/MediaInfoExporter.m
            rm -f GUI/Cocoa/mediainfo.icns
            rm -f GUI/Cocoa/MediaInfo-Info.plist
            rm -f GUI/Cocoa/MediaInfo_Prefix.pch
            rm -f GUI/Cocoa/MyWindowController.m
            rm -f GUI/Cocoa/nl.lproj/About.strings
            rm -f GUI/Cocoa/nl.lproj/Localizable.strings
            rm -f GUI/Cocoa/nl.lproj/MainMenu.strings
            rm -f GUI/Cocoa/nl.lproj/MyWindow.strings
            rm -f GUI/Cocoa/nl.lproj/Preferences.strings
            rm -f GUI/Cocoa/NSString+wchar.m
            rm -f GUI/Cocoa/oMediaInfoList.mm
            rm -f GUI/Cocoa/pl.lproj/About.strings
            rm -f GUI/Cocoa/pl.lproj/Localizable.strings
            rm -f GUI/Cocoa/pl.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pl.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pl.lproj/Preferences.strings
            rm -f GUI/Cocoa/PreferencesWindowController.m
            rm -f GUI/Cocoa/pt.lproj/About.strings
            rm -f GUI/Cocoa/pt.lproj/Localizable.strings
            rm -f GUI/Cocoa/pt.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pt.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pt.lproj/Preferences.strings
            rm -f GUI/Cocoa/pt-PT.lproj/About.strings
            rm -f GUI/Cocoa/pt-PT.lproj/Localizable.strings
            rm -f GUI/Cocoa/pt-PT.lproj/MainMenu.strings
            rm -f GUI/Cocoa/pt-PT.lproj/MyWindow.strings
            rm -f GUI/Cocoa/pt-PT.lproj/Preferences.strings
            rm -f GUI/Cocoa/ro.lproj/About.strings
            rm -f GUI/Cocoa/ro.lproj/Localizable.strings
            rm -f GUI/Cocoa/ro.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ro.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ro.lproj/Preferences.strings
            rm -f GUI/Cocoa/ru.lproj/About.strings
            rm -f GUI/Cocoa/ru.lproj/Localizable.strings
            rm -f GUI/Cocoa/ru.lproj/MainMenu.strings
            rm -f GUI/Cocoa/ru.lproj/MyWindow.strings
            rm -f GUI/Cocoa/ru.lproj/Preferences.strings
            rm -f GUI/Cocoa/sk.lproj/About.strings
            rm -f GUI/Cocoa/sk.lproj/Localizable.strings
            rm -f GUI/Cocoa/sk.lproj/MainMenu.strings
            rm -f GUI/Cocoa/sk.lproj/MyWindow.strings
            rm -f GUI/Cocoa/sk.lproj/Preferences.strings
            rm -f GUI/Cocoa/sv.lproj/About.strings
            rm -f GUI/Cocoa/sv.lproj/Localizable.strings
            rm -f GUI/Cocoa/sv.lproj/MainMenu.strings
            rm -f GUI/Cocoa/sv.lproj/MyWindow.strings
            rm -f GUI/Cocoa/sv.lproj/Preferences.strings
            rm -f GUI/Cocoa/TreeOutlineDelegate.m
            rm -f GUI/Cocoa/TreeOutline.m
            rm -f GUI/Cocoa/tr.lproj/About.strings
            rm -f GUI/Cocoa/tr.lproj/Localizable.strings
            rm -f GUI/Cocoa/tr.lproj/MainMenu.strings
            rm -f GUI/Cocoa/tr.lproj/MyWindow.strings
            rm -f GUI/Cocoa/tr.lproj/Preferences.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/About.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/Localizable.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/MainMenu.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/MyWindow.strings
            rm -f GUI/Cocoa/zh-Hans.lproj/Preferences.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/About.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/Localizable.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/MainMenu.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/MyWindow.strings
            rm -f GUI/Cocoa/zh-Hant.lproj/Preferences.strings
            rm -f GUI/Qt/sheet system.xmi
            rm -f Install/MediaInfo_Extensions.nsh
            rm -f Resource/Image/Windows_Finish.bmp
        cd ..
    cd ..

    if $MakeArchives; then
        echo "3: compressing..."
        cd $WPath/MI
        if ! b.path.dir? ../archives; then
            mkdir ../archives
        fi
        #(GZIP=-9 tar -czf ../archives/mediainfo${Version}.tgz MediaInfo)
        #(BZIP=-9 tar -cjf ../archives/mediainfo${Version}.tbz MediaInfo)
        (XZ_OPT=-9 tar -cJf ../archives/mediainfo${Version}.txz MediaInfo)
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
                mkdir -p $WPath
            fi
        fi
    fi
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

    unset -v WPath MI_source
    unset -v LinuxCompil WindowsCompil LinuxPackages AllTarget
    unset -v CleanUp MakeArchives

}
