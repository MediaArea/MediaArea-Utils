# MediaInfoLib/Release/UpgradeVersion.sh
# Upgrade the version number of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function btask.UpgradeVersion.run () {

    local Repo MIL_source MIL_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="git://github.com/MediaArea/MediaInfoLib/"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MIL_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo $Repo $WPath
        MIL_source=${WPath}/MediaInfoLib
        # For lisibility after git, otherwise not needed
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    MIL_files[((index++))]="Source/MediaInfo/MediaInfo_Config.cpp"
    MIL_files[((index++))]="Project/GNU/libmediainfo.dsc"
    MIL_files[((index++))]="Project/GNU/libmediainfo.spec"
    MIL_files[((index++))]="Project/Solaris/mkpkg"
    MIL_files[((index++))]="debian/changelog"
    MIL_files[((index++))]="debian/control"
    MIL_files[((index++))]="Project/GNU/Library/configure.ac"
    MIL_files[((index++))]="Source/Install/MediaInfo_DLL_Windows_i386.nsi"
    MIL_files[((index++))]="Source/Install/MediaInfo_DLL_Windows_x64.nsi"
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
        updateFile $Version_old_escaped $Version_new "${MIL_source}/${MIL_file}"
    done
    unset -v MIL_files

    echo
    echo "Passage for version with commas..."
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
        updateFile $Version_old_comma $Version_new_comma "${MIL_source}/${MIL_file}"
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

}
