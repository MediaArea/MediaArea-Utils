# DVAnalyzer/Release/UpgradeVersion.sh
# Upgrade the version number of DVAnalyzer

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local Source Files index

    if [ $(b.opt.get_opt --source-path) ]; then
        Source="$SDir"
    else
        getRepo $Repo "$WDir"
        Source="$WDir/$Project"
        # For lisibility after git
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$Source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$Source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$Source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    Files[((index++))]="Project/GNU/dvanalyzer.spec"
    Files[((index++))]="Project/GNU/dvanalyzer.dsc"
    Files[((index++))]="Project/GNU/PKGBUILD"
    Files[((index++))]="Project/Mac/Info.plist"
    Files[((index++))]="Project/OBS/deb7.dsc"
    Files[((index++))]="Project/OBS/deb7.debian/changelog"
    Files[((index++))]="debian/changelog"
    Files[((index++))]="Source/Common/Common_About.cpp"
    Files[((index++))]="Project/MSVC2015/CLI/AVPS_DV_Analyzer_CLI.rc"
    Files[((index++))]="Project/MSVC2015/GUI/AVPS_DV_Analyzer_GUI.rc"
    Files[((index++))]="Project/MSVC2017/CLI/AVPS_DV_Analyzer_CLI.rc"
    Files[((index++))]="Project/MSVC2017/GUI/AVPS_DV_Analyzer_GUI.rc"
    Files[((index++))]="Project/QtCreator/dvanalyzer-gui.rc"
    Files[((index++))]="Source/Install/AVPS_DV_Analyzer_GUI_Windows_i386.nsi"
    Files[((index++))]="Source/Install/AVPS_DV_Analyzer_GUI_Windows_x64.nsi"

    # Make the replacements
    for File in ${Files[@]}
    do
        echo "${Source}/${File}"
        updateFile "$Version_old_escaped" $Version_new "${Source}/${File}"
    done

    echo
    echo "Passage for version AA,BB,CC,DD ..."
    unset -v Files
    index=0
    Files[((index++))]="Project/MSVC2015/CLI/AVPS_DV_Analyzer_CLI.rc"
    Files[((index++))]="Project/MSVC2015/GUI/AVPS_DV_Analyzer_GUI.rc"
    Files[((index++))]="Project/MSVC2017/CLI/AVPS_DV_Analyzer_CLI.rc"
    Files[((index++))]="Project/MSVC2017/GUI/AVPS_DV_Analyzer_GUI.rc"
    Files[((index++))]="Project/QtCreator/dvanalyzer-gui.rc"

    for File in ${Files[@]}
    do
        echo "${Source}/${File}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch,$Version_old_build $Version_new_major,$Version_new_minor,$Version_new_patch,$Version_new_build "${Source}/${File}"
    done

    # Update MediaInfoLib required version
    if [ $(b.opt.get_opt --mil-version) ]; then
        echo
        MIL_version=$(sanitize_arg $(b.opt.get_opt --mil-version))
        echo "Update MediaInfoLib in Project/GNU/dvanalyzer.spec"
        updateFile "%global libmediainfo_version\(\s\+\)[0-9.-]\+" "%global libmediainfo_version\1$MIL_version" "${Source}"/Project/GNU/dvanalyzer.spec
        echo "Update MediaInfoLib in Project/GNU/dvanalyzer.dsc"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${Source}"/Project/GNU/dvanalyzer.dsc
        echo "Update MediaInfoLib in Project/GNU/PKGBUILD"
        updateFile "libmediainfo>=[0-9.-]\+" "libmediainfo>=$MIL_version" "${Source}"/Project/GNU/PKGBUILD
        echo "Update MediaInfoLib in debian/control"
        updateFile "libmediainfo-dev (>= [0-9.-]\+)" "libmediainfo-dev (>= $MIL_version)" "${Source}"/debian/control
    fi

    # Update ZenLib required version
    if [ $(b.opt.get_opt --zl-version) ]; then
        echo
        ZL_version=$(sanitize_arg $(b.opt.get_opt --zl-version))
        echo "Update ZenLib in Project/GNU/dvanalyzer.spec"
        updateFile "%global libzen_version\(\s\+\)[0-9.-]\+" "%global libzen_version\1$ZL_version" "${Source}"/Project/GNU/dvanalyzer.spec
        echo "Update ZenLib in Project/GNU/dvanalyzer.dsc"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${Source}"/Project/GNU/dvanalyzer.dsc
        echo "Update ZenLib in Project/GNU/PKGBUILD"
        updateFile "libzen>=[0-9.-]\+" "libzen>=$ZL_version" "${Source}"/Project/GNU/PKGBUILD
        echo "Update ZenLib in debian/control"
        updateFile "libzen-dev (>= [0-9.-]\+)" "libzen-dev (>= $ZL_version)" "${Source}"/debian/control
    fi
}
