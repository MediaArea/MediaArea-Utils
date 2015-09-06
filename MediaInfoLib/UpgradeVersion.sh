# MediaInfoLib/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local Repo MIL_source MIL_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="https://github.com/MediaArea/MediaInfoLib.git"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source="$SDir"
    else
        getRepo $Repo "$WDir"
        MIL_source="$WDir"/MediaInfoLib
        # For lisibility after git
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    MIL_files[((index++))]="Source/MediaInfo/MediaInfo_Config.cpp"
    MIL_files[((index++))]="Project/GNU/Library/configure.ac"
    MIL_files[((index++))]="Project/GNU/libmediainfo.spec"
    MIL_files[((index++))]="Project/GNU/libmediainfo.dsc"
    MIL_files[((index++))]="debian/changelog"
    MIL_files[((index++))]="Project/OBS/deb6.dsc"
    MIL_files[((index++))]="Project/OBS/deb6.debian/changelog"
    MIL_files[((index++))]="Project/Solaris/mkpkg"

    # Replace old version by new version
    for MIL_file in ${MIL_files[@]}
    do
        echo "${MIL_source}/${MIL_file}"
        updateFile "$Version_old_escaped" $Version_new "${MIL_source}/${MIL_file}"
    done

    echo
    echo "Passage for major.minor.patch.build..."
    unset -v MIL_files
    index=0
    MIL_files[((index++))]="Project/MSVC2005/DLL/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2012/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2012/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2012/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2010/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2010/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2010/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2008/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2008/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2008/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2013/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2013/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2013/ShellExtension/MediaInfoShellExt.rc"

    # Replace old version by new version
    for MIL_file in ${MIL_files[@]}
    do

        echo "${MIL_source}/${MIL_file}"

        # If $Version_old_build is set = it's already include in
        # $Version_old_escaped, so we will try to replace
        # major.minor.patch.build.build, and that doesn't exist in
        # the file
        if [ "$Version_old_build" = "0" ] && [ "$Version_new_build" != "0" ]; then
            updateFile "$Version_old_escaped"\.0 $Version_new "${MIL_source}/${MIL_file}"
            updateFile $Version_old_comma,0 $Version_new_comma "${MIL_source}/${MIL_file}"

        elif [ "$Version_old_build" != "0" ] && [ "$Version_new_build" = "0" ]; then
            updateFile "$Version_old_escaped" $Version_new.0 "${MIL_source}/${MIL_file}"
            updateFile $Version_old_comma $Version_new_comma,0 "${MIL_source}/${MIL_file}"

        # When $Version_old_build and $Version_and_build are set
        # (or not set) together
        else
            updateFile "$Version_old_escaped" $Version_new "${MIL_source}/${MIL_file}"
            updateFile $Version_old_comma $Version_new_comma "${MIL_source}/${MIL_file}"
        fi

    done

    echo
    echo "Replace major/minor/patch in ${MIL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(MediaInfoLib_MAJOR_VERSION $Version_old_major)" \
        "set(MediaInfoLib_MAJOR_VERSION $Version_new_major)" \
        "${MIL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(MediaInfoLib_MINOR_VERSION $Version_old_minor)" \
        "set(MediaInfoLib_MINOR_VERSION $Version_new_minor)" \
        "${MIL_source}/Project/CMake/CMakeLists.txt"
    updateFile "set(MediaInfoLib_PATCH_VERSION $Version_old_patch)" \
        "set(MediaInfoLib_PATCH_VERSION $Version_new_patch)" \
        "${MIL_source}/Project/CMake/CMakeLists.txt"

    echo
    echo "Update Source/Install/MediaInfo_DLL_Windows_i386.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor\.$Version_old_patch $Version_new_major.$Version_new_minor.$Version_new_patch "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_i386.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_build\"" \
        "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_i386.nsi

    echo "Update Source/Install/MediaInfo_DLL_Windows_x64.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor\.$Version_old_patch $Version_new_major.$Version_new_minor.$Version_new_patch "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_x64.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_build\"" \
        "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_x64.nsi

}
