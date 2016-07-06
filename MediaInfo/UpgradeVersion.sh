# MediaInfo/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local Repo MI_source MI_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="https://github.com/MediaArea/MediaInfo"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MI_source="$SDir"
    else
        getRepo $Repo "$WDir"
        MI_source="$WDir"/MediaInfo
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    MI_files[((index++))]="Source/Common/Preferences.h"
    MI_files[((index++))]="Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj"
    MI_files[((index++))]="Project/GNU/CLI/configure.ac"
    MI_files[((index++))]="Project/GNU/GUI/configure.ac"
    MI_files[((index++))]="Project/GNU/PKGBUILD"
    MI_files[((index++))]="debian/changelog"
    MI_files[((index++))]="Project/OBS/deb9.debian/changelog"
    MI_files[((index++))]="Project/OBS/deb7.debian/changelog"
    MI_files[((index++))]="Project/OBS/deb6.debian/changelog"
    # For release mode only
    #MI_files[((index++))]="debian/control"
    #MI_files[((index++))]="Project/OBS/deb9.debian/control"
    #MI_files[((index++))]="Project/OBS/deb7.debian/control"
    #MI_files[((index++))]="Project/OBS/deb6.debian/control"
    MI_files[((index++))]="Project/OBS/obs_mediainfo"
    MI_files[((index++))]="Project/Solaris/mkpkg"
    
    for MI_file in ${MI_files[@]}
    do
        echo "${MI_source}/${MI_file}"
        updateFile "$Version_old_escaped" $Version_new "${MI_source}/${MI_file}"
    done

    echo
    echo "Update ${MI_source}/Project/GNU/mediainfo.spec"
    updateFile "%define mediainfo_version           $Version_old_escaped" "%define mediainfo_version           $Version_new" "${MI_source}"/Project/GNU/mediainfo.spec
    #updateFile "* Tue Jan 01 2009 MediaArea.net SARL <info@mediaarea.net> - $Version_old_escaped" "* Tue Jan 01 2009 MediaArea.net SARL <info@mediaarea.net> - $Version_new" "${MI_source}"/Project/GNU/mediainfo.spec
    echo

    echo
    echo "Update ${MI_source}/Project/OBS/mga5.spec"
    updateFile "%define mediainfo_version           $Version_old_escaped" "%define mediainfo_version           $Version_new" "${MI_source}"/Project/OBS/mga5.spec
    #updateFile "* Tue Jan 01 2009 MediaArea.net SARL <info@mediaarea.net> - $Version_old_escaped" "* Tue Jan 01 2009 MediaArea.net SARL <info@mediaarea.net> - $Version_new" "${MI_source}"/Project/OBS/mga5.spec
    echo
    
    echo "Update ${MI_source}/Project/GNU/mediainfo.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${MI_source}"/Project/GNU/mediainfo.dsc
    # sed will take the last of the longuest strings first and
    # will replace the 3 lines
    updateFile "00000000000000000000000000000000 000000 mediainfo_$Version_old_escaped" "00000000000000000000000000000000 000000 mediainfo_$Version_new" "${MI_source}"/Project/GNU/mediainfo.dsc
    
    echo
    echo "Update ${MI_source}/Project/OBS/deb9.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${MI_source}"/Project/OBS/deb9.dsc
    updateFile "00000000000000000000000000000000 000000 mediainfo_$Version_old_escaped" "00000000000000000000000000000000 000000 mediainfo_$Version_new" "${MI_source}"/Project/OBS/deb9.dsc
    
    echo
    echo "Update ${MI_source}/Project/OBS/deb7.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${MI_source}"/Project/OBS/deb7.dsc
    updateFile "00000000000000000000000000000000 000000 mediainfo_$Version_old_escaped" "00000000000000000000000000000000 000000 mediainfo_$Version_new" "${MI_source}"/Project/OBS/deb7.dsc
    
    echo
    echo "Update ${MI_source}/Project/OBS/deb6.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${MI_source}"/Project/OBS/deb6.dsc
    updateFile "00000000000000000000000000000000 000000 mediainfo_$Version_old_escaped" "00000000000000000000000000000000 000000 mediainfo_$Version_new" "${MI_source}"/Project/OBS/deb6.dsc

    echo
    echo "Passage for major.minor.patch.build..."
    unset -v MI_files
    index=0
    MI_files[((index++))]="Project/BCB/GUI/MediaInfo_GUI.cbproj"
    MI_files[((index++))]="Project/MSVC2012/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2012/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2013/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2013/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/MSVC2015/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2015/CLI/MediaInfo_CLI.rc"

    for MI_file in ${MI_files[@]}
    do

        echo "${MI_source}/${MI_file}"

        # If $Version_old_build is set = it’s already include in
        # $Version_old_escaped, so we will try to replace
        # major.minor.patch.build.build, and that doesn’t exist in
        # the file
        if [ "$Version_old_build" = "0" ] && [ "$Version_new_build" != "0" ]; then
            updateFile "$Version_old_escaped"\.0 $Version_new "${MI_source}/${MI_file}"
            updateFile $Version_old_comma,0 $Version_new_comma "${MI_source}/${MI_file}"

        elif [ "$Version_old_build" != "0" ] && [ "$Version_new_build" = "0" ]; then
            updateFile "$Version_old_escaped" $Version_new.0 "${MI_source}/${MI_file}"
            updateFile $Version_old_comma $Version_new_comma,0 "${MI_source}/${MI_file}"

        # When $Version_old_build and $Version_and_build are set
        # (or not set) together
        else
            updateFile "$Version_old_escaped" $Version_new "${MI_source}/${MI_file}"
            updateFile $Version_old_comma $Version_new_comma "${MI_source}/${MI_file}"
        fi

    done

    echo
    echo "Replace major/minor/patch in ${MI_source}/Project/BCB/GUI/MediaInfo_GUI.cbproj"
    updateFile "<VerInfo_MajorVer>$Version_old_major<\/VerInfo_MajorVer>" \
        "<VerInfo_MajorVer>"$Version_new_major"<\/VerInfo_MajorVer>" \
        "${MI_source}"/Project/BCB/GUI/MediaInfo_GUI.cbproj
    updateFile "<VerInfo_MinorVer>$Version_old_minor<\/VerInfo_MinorVer>" \
        "<VerInfo_MinorVer>"$Version_new_minor"<\/VerInfo_MinorVer>" \
        "${MI_source}"/Project/BCB/GUI/MediaInfo_GUI.cbproj
    updateFile "<VerInfo_Release>$Version_old_patch<\/VerInfo_Release>" \
        "<VerInfo_Release>"$Version_new_patch"<\/VerInfo_Release>" \
        "${MI_source}"/Project/BCB/GUI/MediaInfo_GUI.cbproj

    echo
    echo "Update Source/Install/MediaInfo_GUI_Windows.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor\.$Version_old_patch $Version_new_major.$Version_new_minor.$Version_new_patch "${MI_source}"/Source/Install/MediaInfo_GUI_Windows.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_build\"" \
        "${MI_source}"/Source/Install/MediaInfo_GUI_Windows.nsi

}
