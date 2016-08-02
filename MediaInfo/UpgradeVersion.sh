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

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MI_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$MI_source/Project/version.txt"

    # Update version.txt only in release mode
    if [ "${Version_new%.????????}" == "${Version_new}" ] ; then
        echo "Update version.txt"
        echo "${Version_new}" > "$MI_source/Project/version.txt"
    fi

    echo
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

    # Update MediaInfoLib required version
    if [ $(b.opt.get_opt --mil-version) ]; then
        echo
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        echo "Update MediaInfoLib in Project/GNU/mediainfo.spec"
        updateFile "%define libmediainfo_version\(\s\+\)[0-9.-]\+" "%define libmediainfo_version\1$MIL_version" "${MI_source}"/Project/GNU/mediainfo.spec
        echo "Update MediaInfoLib in Project/GNU/mediainfo.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/GNU/mediainfo.dsc
        echo "Update MediaInfoLib in Project/GNU/PKGBUILD"
        updateFile "libmediainfo>=[0-9.-]\+" "libmediainfo>=$MIL_version" "${MI_source}"/Project/GNU/PKGBUILD
        echo "Update MediaInfoLib in Project/OBS/deb6.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb7.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb9.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb6.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.dsc
        echo "Update MediaInfoLib in Project/OBS/deb7.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb7.dsc
        echo "Update MediaInfoLib in Project/OBS/deb9.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb9.dsc
        echo "Update MediaInfoLib in debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/debian/control
    fi

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        echo "Update ZenLib in Project/GNU/mediainfo.spec"
        updateFile "%define libzen_version\(\s\+\)[0-9.-]\+" "%define libzen_version\1$ZL_version" "${MI_source}"/Project/GNU/mediainfo.spec
        echo "Update ZenLib in Project/GNU/mediainfo.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/GNU/mediainfo.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${MI_source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in Project/OBS/deb6.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        echo "Update ZenLib in Project/OBS/deb7.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        echo "Update ZenLib in Project/OBS/deb9.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        echo "Update ZenLib in Project/OBS/deb6.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.dsc
        echo "Update ZenLib in Project/OBS/deb7.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb7.dsc
        echo "Update ZenLib in Project/OBS/deb9.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb9.dsc
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/debian/control
    fi
}
