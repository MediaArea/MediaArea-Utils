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
        MI_source=$(sanitize_arg $(b.opt.get_opt --source-path))
    else
        getRepo $Repo $WPath
        MI_source=${WPath}/MediaConch_SourceCode
        # For lisibility after git, otherwise not needed
        echo
    fi

    echo "Passage for version with dots..."
    index=0
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 
    MC_files[((index++))]="Project/GNU/mediaconch.dsc" 
    MC_files[((index++))]="Project/GNU/mediaconch.dsc" 
    MC_files[((index++))]="Project/GNU/mediaconch.spec" 
    MC_files[((index++))]="Project/GNU/mediaconch.spec" 
    MC_files[((index++))]="Project/GNU/CLI/configure.ac" 
    MC_files[((index++))]="Project/OBS/obs_mediaconch" 
    MC_files[((index++))]="Project/Mac/mkdmg_GUI" 
    MC_files[((index++))]="Project/Mac/mkdmg_CLI" 
    MC_files[((index++))]="debian/changelog" 
    MC_files[((index++))]="Source/CLI/Help.cpp" 
    MC_files[((index++))]="Source/Install/MediaConch_GUI_Windows.nsi" 

    # Replace old version by new version
    for MC_file in ${MC_files[@]}
    do
        echo ${MI_source}/${MC_file}
        updateFile $Version_old_escaped $Version_new ${MI_source}/${MC_file}

    done
    unset -v MC_files

    echo
    echo "Passage for version with commas..."
    index=0
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/GUI/MediaConch_GUI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 
    MC_files[((index++))]="Project/MSVC2013/CLI/MediaConch_CLI.rc" 

    # Replace old version by new version
    for MC_file in ${MC_files[@]}
    do
        echo ${MI_source}/${MC_file}
        updateFile $Version_old_comma $Version_new_comma ${MI_source}/${MC_file}
    done

}
