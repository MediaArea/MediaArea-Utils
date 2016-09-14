# ZenLib/Release/UpgradeVersion.sh
# Upgrade the version number of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local ZL_source ZL_files index

    if [ $(b.opt.get_opt --source-path) ]; then
        ZL_source="$SDir"
    else
        getRepo $Repo "$WDir"
        ZL_source="$WDir"/ZenLib
        # For lisibility after git
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$ZL_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$ZL_source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$ZL_source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    ZL_files[((index++))]="Project/GNU/Library/configure.ac"
    ZL_files[((index++))]="Project/GNU/libzen.spec"
    ZL_files[((index++))]="Project/GNU/libzen.dsc"
    ZL_files[((index++))]="Project/GNU/PKGBUILD"
    ZL_files[((index++))]="debian/changelog"
    ZL_files[((index++))]="Project/OBS/deb6.dsc"
    ZL_files[((index++))]="Project/OBS/deb6.debian/changelog"
    ZL_files[((index++))]="Project/OBS/deb9.dsc"
    ZL_files[((index++))]="Project/OBS/deb9.debian/changelog"
    ZL_files[((index++))]="Project/Solaris/mkpkg"

    # Make the replacements
    for ZL_file in ${ZL_files[@]}
    do
        echo "${ZL_source}/${ZL_file}"
        updateFile "$Version_old_escaped" $Version_new "${ZL_source}/${ZL_file}"
    done

    echo
    echo "Replace major/minor/patch in ${ZL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(ZenLib_MAJOR_VERSION \"$Version_old_major\")" \
        "set(ZenLib_MAJOR_VERSION \"$Version_new_major\")" \
        "${ZL_source}"/Project/CMake/CMakeLists.txt
    updateFile "set(ZenLib_MINOR_VERSION \"$Version_old_minor\")" \
        "set(ZenLib_MINOR_VERSION \"$Version_new_minor\")" \
        "${ZL_source}"/Project/CMake/CMakeLists.txt
    updateFile "set(ZenLib_PATCH_VERSION \"$Version_old_patch\")" \
        "set(ZenLib_PATCH_VERSION \"$Version_new_patch\")" \
        "${ZL_source}"/Project/CMake/CMakeLists.txt

}
