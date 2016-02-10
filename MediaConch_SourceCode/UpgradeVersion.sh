# MediaConch_SourceCode/Release/UpgradeVersion.sh
# Upgrade the version number of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local Repo MC_source MC_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="https://github.com/MediaArea/MediaConch_SourceCode"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MC_source="$SDir"
    else
        getRepo $Repo "$WDir"
        MC_source="$WDir"/MediaConch_SourceCode
        echo
    fi

    echo "Passage for version YY.MM ..."
    index=0
    MC_files[((index++))]="License.html"
    MC_files[((index++))]="Source/CLI/Help.cpp"
    MC_files[((index++))]="Source/Daemon/Daemon.cpp"
    MC_files[((index++))]="Project/GNU/mediaconch.spec"
    MC_files[((index++))]="Project/GNU/mediaconch.dsc"
    MC_files[((index++))]="debian/changelog"

    for MC_file in ${MC_files[@]}
    do
        echo "${MC_source}/${MC_file}"
        updateFile "$Version_old_escaped" $Version_new "${MC_source}/${MC_file}"
    done

    echo
    echo "Update ${MC_source}/Project/GNU/mediaconch.dsc"
    updateFile "Version: $Version_old_escaped" "Version: $Version_new" "${MC_source}"/Project/GNU/mediaconch.dsc
    # sed will take the last of the longuest strings first and
    # will replace the 3 lines
    updateFile "00000000000000000000000000000000 000000 mediaconch_$Version_old_escaped" "00000000000000000000000000000000 000000 mediaconch_$Version_new" "${MC_source}"/Project/GNU/mediaconch.dsc
    
    echo
    echo "Update ${MC_source}/Project/GNU/mediaconch.spec"
    updateFile "%define mediaconch_version          $Version_old_escaped" "%define mediaconch_version          $Version_new" "${MC_source}"/Project/GNU/mediaconch.spec

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
    MC_files[((index++))]="Project/OBS/obs_mediaconch" 

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

    for MC_file in ${MC_files[@]}
    do
        echo "${MC_source}/${MC_file}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch "${MC_source}/${MC_file}"
    done

    echo
    echo "Update Source/Install/MediaConch_GUI_Windows.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor $Version_new_major.$Version_new_minor "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_patch\.0\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_new_patch\.0\"" \
        "${MC_source}"/Source/Install/MediaConch_GUI_Windows.nsi

}
