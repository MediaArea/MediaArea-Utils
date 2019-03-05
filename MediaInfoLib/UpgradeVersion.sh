# MediaInfoLib/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local MIL_source MIL_files index

    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source="$SDir"
    else
        getRepo $Repo "$WDir"
        MIL_source="$WDir"/MediaInfoLib
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MIL_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$MIL_source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$MIL_source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    MIL_files[((index++))]="Source/MediaInfo/MediaInfo_Config.cpp"
    MIL_files[((index++))]="Project/GNU/Library/configure.ac"
    MIL_files[((index++))]="Project/GNU/libmediainfo.spec"
    MIL_files[((index++))]="Project/GNU/libmediainfo.dsc"
    MIL_files[((index++))]="Project/GNU/PKGBUILD"
    MIL_files[((index++))]="debian/changelog"
    MIL_files[((index++))]="Project/OBS/deb6.dsc"
    MIL_files[((index++))]="Project/OBS/deb6.debian/changelog"
    # Since TinyXML2 is back as buildin for deb distribs
    #MIL_files[((index++))]="Project/OBS/u12.04.dsc"
    #MIL_files[((index++))]="Project/OBS/u12.04.debian/changelog"
    MIL_files[((index++))]="Project/OBS/deb9.dsc"
    MIL_files[((index++))]="Project/OBS/deb9.debian/changelog"
    MIL_files[((index++))]="Project/Solaris/mkpkg"

    for MIL_file in ${MIL_files[@]}
    do
        echo "${MIL_source}/${MIL_file}"
        updateFile "$Version_old_escaped" $Version_new "${MIL_source}/${MIL_file}"
    done

    echo
    echo "Passage for major.minor.patch.build..."
    unset -v MIL_files
    index=0
    MIL_files[((index++))]="Project/MSVC2010/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2010/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2010/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2012/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2012/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2012/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2013/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2013/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2013/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2015/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2015/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2015/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2017/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2017/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2017/ShellExtension/MediaInfoShellExt.rc"
    MIL_files[((index++))]="Project/MSVC2019/Dll/MediaInfo.rc"
    MIL_files[((index++))]="Project/MSVC2019/Example/HowToUse.rc"
    MIL_files[((index++))]="Project/MSVC2019/ShellExtension/MediaInfoShellExt.rc"

    for MIL_file in ${MIL_files[@]}
    do

        echo "${MIL_source}/${MIL_file}"
        updateFile "$Version_old_major\.$Version_old_minor\.$Version_old_patch" $Version_new_major.$Version_new_minor.$Version_new_patch "${MIL_source}/${MIL_file}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch "${MIL_source}/${MIL_file}"

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
    updateFile $Version_old_major\.$Version_old_minor $Version_new_major.$Version_new_minor "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_i386.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_patch\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_patch.$Version_new_build\"" \
        "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_i386.nsi

    echo "Update Source/Install/MediaInfo_DLL_Windows_x64.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor $Version_new_major.$Version_new_minor "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_x64.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_patch\.$Version_old_build\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_patch.$Version_new_build\"" \
        "${MIL_source}"/Source/Install/MediaInfo_DLL_Windows_x64.nsi

    echo "Replace major/minor in ${MIL_source}/Project/GNU/libmediainfo.spec"
    updateFile "%global libmediainfo_version_major\(\s\+\)$Version_old_major" \
        "%global libmediainfo_version_major\1$Version_new_major" \
        "${MIL_source}/Project/GNU/libmediainfo.spec"
    updateFile "%global libmediainfo_version_minor\(\s\+\)$Version_old_minor" \
        "%global libmediainfo_version_minor\1$Version_new_minor" \
        "${MIL_source}/Project/GNU/libmediainfo.spec"

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        ZL_version_array=( ${ZL_version//./ } )
        echo "Update ZenLib in Project/GNU/libmediainfo.spec"
        updateFile "%global libzen_version\(\s\+\)[0-9.-]\+" "%global libzen_version\1$ZL_version" "${MIL_source}"/Project/GNU/libmediainfo.spec
        updateFile "%global libzen_version_major\(\s\+\)[0-9]\+" "%global libzen_version_major\1${ZL_version_array[0]:-0}" "${MIL_source}/Project/GNU/libmediainfo.spec"
        updateFile "%global libzen_version_minor\(\s\+\)[0-9]\+" "%global libzen_version_minor\1${ZL_version_array[1]:-0}" "${MIL_source}/Project/GNU/libmediainfo.spec"
        updateFile "%global libzen_version_release\(\s\+\)[0-9]\+" "%global libzen_version_release\1${ZL_version_array[2]:-0}" "${MIL_source}/Project/GNU/libmediainfo.spec"
        echo "Update ZenLib in Project/GNU/libmediainfo.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/Project/GNU/libmediainfo.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${MIL_source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in Project/OBS/deb6.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb6.debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb6.debian/control
        echo "Update ZenLib in Project/OBS/deb9.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb9.debian/control
        updateFile "libzen0v5 (>= [0-9.-]\+)" "libzen0v5 (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb9.debian/control
        echo "Update ZenLib in Project/OBS/deb6.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb6.dsc
        echo "Update ZenLib in Project/OBS/deb9.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/Project/OBS/deb9.dsc
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MIL_source}"/debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MIL_source}"/debian/control
    fi

}
