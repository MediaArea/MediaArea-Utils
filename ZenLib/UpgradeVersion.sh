# ZenLib/Release/UpgradeVersion.sh
# Upgrade the version number of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

function btask.UpgradeVersion.run () {

    local Repo MI_source MI_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="git://github.com/MediaArea/ZenLib/"
    fi
   
    if [ $(b.opt.get_opt --source-path) ]; then
        ZL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo $Repo $WPath
        ZL_source=${WPath}/ZenLib
        # For lisibility after git, otherwise not needed
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    ZL_files[((index++))]="Project/GNU/libzen.dsc"
    ZL_files[((index++))]="Project/GNU/libzen.spec"
    ZL_files[((index++))]="Project/Solaris/mkpkg"
    ZL_files[((index++))]="debian/changelog"
    ZL_files[((index++))]="debian/control"
    ZL_files[((index++))]="Project/GNU/Library/configure.ac"

    # Replace old version by new version
    for ZL_file in ${ZL_files[@]}
    do
        echo "${ZL_source}/${ZL_file}"
        updateFile $Version_old_escaped $Version_new "${ZL_source}/${ZL_file}"
    done

    echo
    echo "Replace major/minor/patch in ${ZL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(ZenLib_MAJOR_VERSION \"$Version_old_major\")" \
        "set(ZenLib_MAJOR_VERSION \"$Version_new_major\")" \
        "${ZL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(ZenLib_MINOR_VERSION \"$Version_old_minor\")" \
        "set(ZenLib_MINOR_VERSION \"$Version_new_minor\")" \
        "${ZL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(ZenLib_PATCH_VERSION \"$Version_old_patch\")" \
        "set(ZenLib_PATCH_VERSION \"$Version_new_patch\")" \
        "${ZL_source}/Project/CMake/CMakeLists.txt"

}
