# dvrescue/Release/UpgradeVersion.sh
# Upgrade the version number of dvrescue

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local _source DR_files index

    if [ $(b.opt.get_opt --source-path) ]; then
        DR_source="$SDir"
    else
        getRepo $Repo "$WDir"
        DR_source="$WDir"/dvrescue
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$DR_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$DR_source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$DR_source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    DR_files[((index++))]="debian/changelog"
    DR_files[((index++))]="Project/Mac/Info.plist"
    DR_files[((index++))]="Source/Common/Config.h"

    for DR_file in ${DR_files[@]}
    do
        echo "${DR_source}/${DR_file}"
        updateFile "$Version_old_escaped" $Version_new "${DR_source}/${DR_file}"
    done

    echo
    echo "Update ${DR_source}/Project/GNU/dvrescue.spec"
    updateFile "%global dvrescue_version\(\s\+\)[0-9.-]\+" "%global dvrescue_version\1$Version_new" "${DR_source}"/Project/GNU/dvrescue.spec

    echo
    echo "Update ${DR_source}/Project/GNU/dvrescue.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${DR_source}"/Project/GNU/dvrescue.dsc
    # sed will take the last of the longuest strings first and
    # will replace the 3 lines
    updateFile "00000000000000000000000000000000 000000 dvrescue_$Version_old_escaped" "00000000000000000000000000000000 000000 dvrescue_$Version_new" "${DR_source}"/Project/GNU/dvrescue.dsc

    echo
    echo "Update ${DR_source}/Project/GNU/PKGBUILD"
    updateFile "pkgver=$Version_old_escaped" "pkgver=$Version_new" "${DR_source}"/Project/GNU/PKGBUILD

    echo
    echo "Passage for major.minor.patch.build..."
    unset -v DR_files
    index=0
    DR_files[((index++))]="Project/MSVC2017/CLI/DVRescue.rc"

    for DR_file in ${DR_files[@]}
    do
        echo "${DR_source}/${DR_file}"
        updateFile "$Version_old_major\.$Version_old_minor\.$Version_old_patch" $Version_new_major.$Version_new_minor.$Version_new_patch "${DR_source}/${DR_file}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch "${DR_source}/${DR_file}"
    done

    # Update MediaInfoLib required version
    if [ $(b.opt.get_opt --mil-version) ]; then
        echo
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        MIL_version_array=( ${MIL_version//./ } )
        echo "Update MediaInfoLib in Project/GNU/dvrescue.spec"
        updateFile "%global libmediainfo_version\(\s\+\)[0-9.-]\+" "%global libmediainfo_version\1$MIL_version" "${DR_source}"/Project/GNU/dvrescue.spec
        updateFile "%global libmediainfo_version_major\(\s\+\)[0-9]\+" "%global libmediainfo_version_major\1${MIL_version_array[0]:-0}" "${DR_source}/Project/GNU/mediainfo.spec"
        updateFile "%global libmediainfo_version_minor\(\s\+\)[0-9]\+" "%global libmediainfo_version_minor\1${MIL_version_array[1]:-0}" "${DR_source}/Project/GNU/mediainfo.spec"
        echo "Update MediaInfoLib in Project/GNU/mediainfo.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${DR_source}"/Project/GNU/dvrescue.dsc
        echo "Update MediaInfoLib in Project/GNU/PKGBUILD"
        updateFile "libmediainfo>=[0-9.-]\+" "libmediainfo>=$MIL_version" "${DR_source}"/Project/GNU/PKGBUILD
        echo "Update MediaInfoLib in debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${DR_source}"/debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${DR_source}"/debian/control
    fi

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        ZL_version_array=( ${ZL_version//./ } )
        echo "Update ZenLib in Project/GNU/dvrescue.spec"
        updateFile "%global libzen_version\(\s\+\)[0-9.-]\+" "%global libzen_version\1$ZL_version" "${DR_source}"/Project/GNU/dvrescue.spec
        updateFile "%global libzen_version_major\(\s\+\)[0-9]\+" "%global libzen_version_major\1${ZL_version_array[0]:-0}" "${DR_source}/Project/GNU/dvrescue.spec"
        updateFile "%global libzen_version_minor\(\s\+\)[0-9]\+" "%global libzen_version_minor\1${ZL_version_array[1]:-0}" "${DR_source}/Project/GNU/dvrescue.spec"
        updateFile "%global libzen_version_release\(\s\+\)[0-9]\+" "%global libzen_version_release\1${ZL_version_array[2]:-0}" "${DR_source}/Project/GNU/dvrescue.spec"
        echo "Update ZenLib in Project/GNU/dvrescue.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${DR_source}"/Project/GNU/dvrescue.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${DR_source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${DR_source}"/debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${DR_source}"/debian/control
    fi
}
