# MediaConch_SourceCode/Release/UpgradeVersion.sh
# Upgrade the version number of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local MC_source MC_files index

    if [ $(b.opt.get_opt --source-path) ]; then
        MC_source="$SDir"
    else
        getRepo $Repo "$WDir"
        MC_source="$WDir"/MediaConch_SourceCode
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MC_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$MC_source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$MC_source/Project/version.txt"

    echo
    echo "Passage for version YY.MM ..."
    index=0
    MC_files[((index++))]="License.html"
    MC_files[((index++))]="Source/Common/Version.h"
    MC_files[((index++))]="Project/GNU/mediaconch.dsc"
    MC_files[((index++))]="debian/changelog"
    MC_files[((index++))]="Project/OBS/deb7.dsc"
    MC_files[((index++))]="Project/OBS/deb7.debian/changelog"
    MC_files[((index++))]="Project/OBS/deb9.dsc"
    MC_files[((index++))]="Project/OBS/deb9.debian/changelog"
    MC_files[((index++))]="Project/Mac/Info-ns.plist"
    MC_files[((index++))]="Project/Mac/Info.plist"

    for MC_file in ${MC_files[@]}
    do
        echo "${MC_source}/${MC_file}"
        echo replace $Version_old_escaped by $Version_new in $MC_file
        updateFile "$Version_old_escaped" $Version_new "${MC_source}/${MC_file}"
    done

    echo
    echo "Update ${MC_source}/Project/GNU/mediaconch.spec"
    updateFile "%global mediaconch_version          $Version_old_escaped" "%global mediaconch_version          $Version_new" "${MC_source}"/Project/GNU/mediaconch.spec

    echo "Update ${MC_source}/Project/GNU/PKGBUILD"
    updateFile "pkgver=$Version_old_escaped" "pkgver=$Version_new" "${MC_source}"/Project/GNU/PKGBUILD

    echo
    echo "Update ${MC_source}/Project/AppImage/Recipe.sh"
    updateFile "VERSION=$Version_old_escaped" "VERSION=$Version_new" "${MC_source}"/Project/AppImage/Recipe.sh

    echo
    echo "Update ${MC_source}/Project/Snap/mediaconch/snapcraft.yaml"
    updateFile "version: $Version_old_escaped" "version: $Version_new" "${MC_source}"/Project/Snap/mediaconch/snapcraft.yaml

    echo
    echo "Update ${MC_source}/Project/Snap/mediaconch-server/snapcraft.yaml"
    updateFile "version: $Version_old_escaped" "version: $Version_new" "${MC_source}"/Project/Snap/mediaconch-server/snapcraft.yaml

    echo
    echo "Update ${MC_source}/Project/Snap/mediaconch-gui/snapcraft.yaml"
    updateFile "version: $Version_old_escaped" "version: $Version_new" "${MC_source}"/Project/Snap/mediaconch-gui/snapcraft.yaml

    echo
    echo "Passage for version YY.MM.patch ..."
    unset -v MC_files
    index=0
    MC_files[((index++))]="Project/GNU/CLI/configure.ac"
    MC_files[((index++))]="Project/GNU/Server/configure.ac"
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2013/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2015/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2015/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2015/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2017/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2017/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2017/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2019/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2019/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2019/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2022/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2022/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2022/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2022/DLL/MediaConch_DLL.rc"
    MC_files[((index++))]="Project/Qt/MediaConch.rc"

    for MC_file in ${MC_files[@]}
    do
        echo "${MC_source}/${MC_file}"
        updateFile "$Version_old_major\.$Version_old_minor\.$Version_old_patch" $Version_new_major.$Version_new_minor.$Version_new_patch "${MC_source}/${MC_file}"
    done

    echo
    echo "Passage for version YY,MM,patch ..."
    unset -v MC_files
    index=0
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2013/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2015/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2015/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2015/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2017/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2017/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2017/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2019/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2019/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2019/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2022/CLI/MediaConch_CLI.rc"
    MC_files[((index++))]="Project/MSVC2022/Server/MediaConch-Server.rc"
    MC_files[((index++))]="Project/MSVC2022/GUI/MediaConch_GUI.rc"
    MC_files[((index++))]="Project/MSVC2022/DLL/MediaConch_DLL.rc"
    MC_files[((index++))]="Project/Qt/MediaConch.rc"

    for MC_file in ${MC_files[@]}
    do
        echo "${MC_source}/${MC_file}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch "${MC_source}/${MC_file}"
    done

    echo
    echo "Update Source/Install/MediaConch_GUI_Windows.nsi ..."
    updateFile $Version_old $Version_new "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi
    if [ "$Version_new_build" -ne 0 ] ; then
        updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}[0-9.]*\"" "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\"" "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi
    elif [ "$Version_new_patch" -ne 0 ] ; then
        updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}[0-9.]*\"" "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_build\"" "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi
    else
        updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}[0-9.]*\"" "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}.$Version_new_patch.$Version_new_build\"" "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi
    fi

    # Update MediaInfoLib required version
    if [ $(b.opt.get_opt --mil-version) ]; then
        echo
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        echo "Update MediaInfoLib in Project/GNU/mediainfo.spec"
        updateFile "%global libmediainfo_version\(\s\+\)[0-9.-]\+" "%global libmediainfo_version\1$MIL_version" "${MC_source}"/Project/GNU/mediaconch.spec
        echo "Update MediaInfoLib in Project/GNU/mediainfo.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/Project/GNU/mediaconch.dsc
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MC_source}"/Project/GNU/mediaconch.dsc
        echo "Update MediaInfoLib in Project/OBS/deb7.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/Project/OBS/deb7.dsc
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MC_source}"/Project/OBS/deb7.dsc
        echo "Update MediaInfoLib in Project/OBS/deb9.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/Project/OBS/deb9.dsc
        updateFile "libmediainfo0v5 (>= [0-9.-]\+)" "libmediainfo0v5 (>= $MIL_version)" "${MC_source}"/Project/OBS/deb9.dsc
        echo "Update MediaInfoLib in Project/GNU/PKGBUILD"
        updateFile "libmediainfo>=[0-9.-]\+" "libmediainfo>=$MIL_version" "${MC_source}"/Project/GNU/PKGBUILD
        echo "Update MediaInfoLib in debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MC_source}"/debian/control
        echo "Update MediaInfoLib in Project/OBS/deb7.debian"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/Project/OBS/deb7.debian/control
        updateFile "libmediainfo0 (>= [0-9.-]\+)" "libmediainfo0 (>= $MIL_version)" "${MC_source}"/Project/OBS/deb7.debian/control
        echo "Update MediaInfoLib in Project/OBS/deb9.debian"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${MC_source}"/Project/OBS/deb9.debian/control
        updateFile "libmediainfo0v5 (>= [0-9.-]\+)" "libmediainfo0v5 (>= $MIL_version)" "${MC_source}"/Project/OBS/deb9.debian/control
    fi

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        echo "Update ZenLib in Project/GNU/mediainfo.spec"
        updateFile "%global libzen_version\(\s\+\)[0-9.-]\+" "%global libzen_version\1$ZL_version" "${MC_source}"/Project/GNU/mediaconch.spec
        echo "Update ZenLib in Project/GNU/mediainfo.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/Project/GNU/mediaconch.dsc
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MC_source}"/Project/GNU/mediaconch.dsc
        echo "Update ZenLib in Project/OBS/deb7.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/Project/OBS/deb7.dsc
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MC_source}"/Project/OBS/deb7.dsc
        echo "Update ZenLib in Project/OBS/deb9.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/Project/OBS/deb9.dsc
        updateFile "libzen0v5 (>= [0-9.-]\+)" "libzen0v5 (>= $ZL_version)" "${MC_source}"/Project/OBS/deb9.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${MC_source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MC_source}"/debian/control
        echo "Update ZenLib in Project/OBS/deb7.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/Project/OBS/deb7.debian/control
        updateFile "libzen0 (>= [0-9.-]\+)" "libzen0 (>= $ZL_version)" "${MC_source}"/Project/OBS/deb7.debian/control
        echo "Update ZenLib in Project/OBS/deb9.debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${MC_source}"/Project/OBS/deb9.debian/control
        updateFile "libzen0v5 (>= [0-9.-]\+)" "libzen0v5 (>= $ZL_version)" "${MC_source}"/Project/OBS/deb9.debian/control
    fi
}
