# MediaConch_SourceCode/Release/UpgradeVersion.sh
# Upgrade the version number of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function btask.UpgradeVersion.run () {

    local Repo MC_source MC_files index

    if [ $(b.opt.get_opt --repo) ]; then
        Repo=$(sanitize_arg $(b.opt.get_opt --repo))
    else
        Repo="https://github.com/MediaArea/MediaConch_SourceCode/"
    fi

    if [ $(b.opt.get_opt --source-path) ]; then
        MC_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo $Repo $WPath
        MC_source=${WPath}/MediaConch_SourceCode
        # For lisibility after git, otherwise not needed
        echo
    fi

    #echo "$Version_old_major\.$Version_old_minor\.$Version_old_patch \
    #    => $Version_new_major.$Version_new_minor.$Version_new_patch"

    echo "Passage for version YY.MM ..."
    index=0
    MC_files[((index++))]="Project/GNU/mediaconch.dsc" 
    MC_files[((index++))]="Project/GNU/mediaconch.spec" 
    MC_files[((index++))]="Project/Mac/mkdmg_GUI" 
    MC_files[((index++))]="Project/Mac/mkdmg_CLI" 
    MC_files[((index++))]="Source/CLI/Help.cpp" 

    for MC_file in ${MC_files[@]}
    do
        echo ${MC_source}/${MC_file}
        updateFile $Version_old_escaped $Version_new ${MC_source}/${MC_file}
    done
    unset -v MC_files

    echo
    echo "Passage for version YY.MM.patch ..."
    index=0
    MC_files[((index++))]="Project/GNU/CLI/configure.ac" 
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 
    MC_files[((index++))]="Project/OBS/obs_mediaconch" 
    MC_files[((index++))]="debian/changelog" 

    for MC_file in ${MC_files[@]}
    do
        echo ${MC_source}/${MC_file}
        updateFile $Version_old_major\.$Version_old_minor\.$Version_old_patch $Version_new_major.$Version_new_minor.$Version_new_patch ${MC_source}/${MC_file}
    done
    unset -v MC_files

    echo
    echo "Passage for version YY,MM,patch[,0] ..."
    index=0
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 

    for MC_file in ${MC_files[@]}
    do
        echo ${MC_source}/${MC_file}
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch $Version_new_major,$Version_new_minor,$Version_new_patch ${MC_source}/${MC_file}
    done
    unset -v MC_files

    echo
    echo "Update Source/Install/MediaConch_GUI_Windows.nsi ..."
    updateFile $Version_old_major\.$Version_old_minor $Version_new_major.$Version_new_minor ${MC_source}/Source/Install/MediaConch_GUI_Windows.nsi
    updateFile "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_old_patch\.0\"" \
        "!define PRODUCT_VERSION4 \"\${PRODUCT_VERSION}\.$Version_new_patch\.0\"" \
        ${MC_source}/Source/Install/MediaConch_GUI_Windows.nsi

}
