# MediaInfo/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local MI_source MI_files index

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

    echo "Update version.txt"
    echo "${Version_new}" > "$MI_source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    MI_files[((index++))]="Source/Common/Preferences.h"
    MI_files[((index++))]="Source/GUI/Qt/mainwindow.cpp"
    MI_files[((index++))]="Source/GUI/Android/app/src/main/res/values/strings.xml"
    MI_files[((index++))]="Source/GUI/Android/app/build.gradle"
    MI_files[((index++))]="Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj"
    MI_files[((index++))]="Project/GNU/CLI/configure.ac"
    MI_files[((index++))]="Project/GNU/GUI/configure.ac"
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
    updateFile "%global mediainfo_version           $Version_old_escaped" "%global mediainfo_version           $Version_new" "${MI_source}"/Project/GNU/mediainfo.spec
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
    echo "Update ${MI_source}/Project/AppImage/Recipe.sh"
    updateFile "VERSION=$Version_old_escaped" "VERSION=$Version_new" "${MI_source}"/Project/AppImage/Recipe.sh

    echo
    echo "Update ${MI_source}/Project/Snap/mediainfo/snapcraft.yaml"
    updateFile "version: $Version_old_escaped" "version: $Version_new" "${MI_source}"/Project/Snap/mediainfo/snapcraft.yaml

    echo
    echo "Update ${MI_source}/Project/Snap/mediainfo-gui/snapcraft.yaml"
    updateFile "version: $Version_old_escaped" "version: $Version_new" "${MI_source}"/Project/Snap/mediainfo-gui/snapcraft.yaml

    echo
    echo "Update ${MI_source}/Project/GNU/PKGBUILD"
    updateFile "pkgver=$Version_old_escaped" "pkgver=$Version_new" "${MI_source}"/Project/GNU/PKGBUILD

    echo
    echo "Update ${MI_source}/Project/QMake/GUI/AppxManifest.xml"
    updateFile "Version=\"$((10#$Version_old_major))\.$((10#$Version_old_minor))\.$((10#$Version_old_patch))\.0" "Version=\"$((10#$Version_new_major))\.$((10#$Version_new_minor))\.$((10#$Version_new_patch))\.0" "${MI_source}"/Project/QMake/GUI/AppxManifest.xml

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
    MI_files[((index++))]="Project/MSVC2017/GUI/MediaInfo_GUI.rc"
    MI_files[((index++))]="Project/MSVC2017/CLI/MediaInfo_CLI.rc"
    MI_files[((index++))]="Project/QMake/GUI/mediainfo-gui.rc"
    MI_files[((index++))]="Project/QMake/GUI/MediaInfoQt.pro"

    for MI_file in ${MI_files[@]}
    do

        echo "${MI_source}/${MI_file}"

        updateFile "$Version_old_major\.$Version_old_minor\.$Version_old_patch" $Version_new_major.$Version_new_minor.$Version_new_patch "${MI_source}/${MI_file}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch "${MI_source}/${MI_file}"
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
    updateFile $Version_old_major\.$Version_old_minor $Version_new_major.$Version_new_minor "${MI_source}"/Source/Install/MediaInfo_GUI_Windows.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_patch\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_patch.$Version_new_build\"" \
        "${MI_source}"/Source/Install/MediaInfo_GUI_Windows.nsi

    echo "Replace major/minor in ${MI_source}/Project/GNU/mediainfo.spec"
    updateFile "%global mediainfo_version_major\(\s\+\)$Version_old_major" \
        "%global mediainfo_version_major\1$Version_new_major" \
        "${MI_source}/Project/GNU/mediainfo.spec"
    updateFile "%global mediainfo_version_minor\(\s\+\)$Version_old_minor" \
        "%global mediainfo_version_minor\1$Version_new_minor" \
        "${MI_source}/Project/GNU/mediainfo.spec"

    # Update MediaInfoLib required version
    if [ $(b.opt.get_opt --mil-version) ]; then
        echo
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        MIL_version_array=( ${MIL_version//./ } )
        echo "Update MediaInfoLib in Project/GNU/mediainfo.spec"
        updateFile "%global libmediainfo_version\(\s\+\)[0-9.-]\+" "%global libmediainfo_version\1$MIL_version" "${MI_source}"/Project/GNU/mediainfo.spec
        updateFile "%global libmediainfo_version_major\(\s\+\)[0-9]\+" "%global libmediainfo_version_major\1${MIL_version_array[0]:-0}" "${MI_source}/Project/GNU/mediainfo.spec"
        updateFile "%global libmediainfo_version_minor\(\s\+\)[0-9]\+" "%global libmediainfo_version_minor\1${MIL_version_array[1]:-0}" "${MI_source}/Project/GNU/mediainfo.spec"
        echo "Update MediaInfoLib in Project/GNU/mediainfo.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/GNU/mediainfo.dsc
        echo "Update MediaInfoLib in Project/GNU/PKGBUILD"
        updateFile "libmediainfo>=[0-9.-]\+" "libmediainfo>=$MIL_version" "${MI_source}"/Project/GNU/PKGBUILD
        echo "Update MediaInfoLib in Project/OBS/deb6.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb7.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb9.debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        updateFile "libmediainfo0v5 (>= [0-9.-]\+)" "libmediainfo0v5 (>= $MIL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb6.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb6.dsc
        echo "Update MediaInfoLib in Project/OBS/deb7.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb7.dsc
        echo "Update MediaInfoLib in Project/OBS/deb9.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/Project/OBS/deb9.dsc
        echo "Update MediaInfoLib in debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MI_source}"/debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MI_source}"/debian/control
    fi

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        ZL_version_array=( ${ZL_version//./ } )
        echo "Update ZenLib in Project/GNU/mediainfo.spec"
        updateFile "%global libzen_version\(\s\+\)[0-9.-]\+" "%global libzen_version\1$ZL_version" "${MI_source}"/Project/GNU/mediainfo.spec
        updateFile "%global libzen_version_major\(\s\+\)[0-9]\+" "%global libzen_version_major\1${ZL_version_array[0]:-0}" "${MI_source}/Project/GNU/mediainfo.spec"
        updateFile "%global libzen_version_minor\(\s\+\)[0-9]\+" "%global libzen_version_minor\1${ZL_version_array[1]:-0}" "${MI_source}/Project/GNU/mediainfo.spec"
        updateFile "%global libzen_version_release\(\s\+\)[0-9]\+" "%global libzen_version_release\1${ZL_version_array[2]:-0}" "${MI_source}/Project/GNU/mediainfo.spec"
        echo "Update ZenLib in Project/GNU/mediainfo.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/GNU/mediainfo.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${MI_source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in Project/OBS/deb6.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.debian/control
        echo "Update ZenLib in Project/OBS/deb7.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MI_source}"/Project/OBS/deb7.debian/control
        echo "Update ZenLib in Project/OBS/deb9.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        updateFile "libzen0v5 (>= [0-9.-]\+)" "libzen0v5 (>= $ZL_version)" "${MI_source}"/Project/OBS/deb9.debian/control
        echo "Update ZenLib in Project/OBS/deb6.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb6.dsc
        echo "Update ZenLib in Project/OBS/deb7.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb7.dsc
        echo "Update ZenLib in Project/OBS/deb9.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/Project/OBS/deb9.dsc
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MI_source}"/debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MI_source}"/debian/control
    fi
}
