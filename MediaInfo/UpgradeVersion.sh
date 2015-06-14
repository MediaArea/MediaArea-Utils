# MediaInfo/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function btask.UpgradeVersion.run () {

    local Repo MI_source MI_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="git://github.com/MediaArea/MediaInfo/"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MI_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo $Repo $WPath
        MI_source=${WPath}/MediaInfo
        # For lisibility after git, otherwise not needed
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    MI_files[((index++))]="Source/Common/Preferences.h"
    MI_files[((index++))]="Project/GNU/mediainfo.dsc"
    MI_files[((index++))]="Project/GNU/mediainfo.spec"
    MI_files[((index++))]="Project/Solaris/mkpkg"
    MI_files[((index++))]="debian/changelog"
    MI_files[((index++))]="debian/control"
    MI_files[((index++))]="Project/BCB/GUI/MediaInfo_GUI.cbproj"
    MI_files[((index++))]="Project/OBS/obs_mediainfo"
    MI_files[((index++))]="Project/GNU/CLI/configure.ac"
    MI_files[((index++))]="Project/GNU/GUI/configure.ac"
    MI_files[((index++))]="Source/Install/MediaInfo_GUI_Windows.nsi"
    MI_files[((index++))]="Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj"
    MI_files[((index++))]="Project/MSVC2012/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2012/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2010/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2010/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2008/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2008/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2013/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2013/CLI/MediaInfo_CLI.rc"

    # Replace old version by new version
    for MI_file in ${MI_files[@]}
    do
        echo ${MI_source}/${MI_file}
        updateFile $Version_old_escaped $Version_new ${MI_source}/${MI_file}

    done
    unset -v MI_files index

    echo
    echo "Passage for version with commas..."
    index=0
    MI_files[((index++))]="Project/MSVC2012/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2012/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2010/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2010/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2008/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2008/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2013/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2013/CLI/MediaInfo_CLI.rc"

    # Replace old version by new version
    for MI_file in ${MI_files[@]}
    do
        echo ${MI_source}/${MI_file}
        updateFile $Version_old_comma $Version_new_comma ${MI_source}/${MI_file}
    done

    echo
    echo "Replace major/minor/patch in ${MI_source}/Project/BCB/GUI/MediaInfo_GUI.cbproj"
    updateFile "<VerInfo_MajorVer>$Version_old_major<\/VerInfo_MajorVer>" \
        "<VerInfo_MajorVer>"$Version_new_major"<\/VerInfo_MajorVer>" \
        "${MI_source}/Project/BCB/GUI/MediaInfo_GUI.cbproj"
    updateFile "<VerInfo_MinorVer>$Version_old_minor<\/VerInfo_MinorVer>" \
        "<VerInfo_MinorVer>"$Version_new_minor"<\/VerInfo_MinorVer>" \
        "${MI_source}/Project/BCB/GUI/MediaInfo_GUI.cbproj"
    updateFile "<VerInfo_Release>$Version_old_patch<\/VerInfo_Release>" \
        "<VerInfo_Release>"$Version_new_patch"<\/VerInfo_Release>" \
        "${MI_source}/Project/BCB/GUI/MediaInfo_GUI.cbproj"

}
