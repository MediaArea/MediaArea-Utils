# QCTools/Release/UpgradeVersion.sh
# Upgrade the version number of QCTools

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
        Source="$WDir"/$Project
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

    echo "Update Sources/Cli/version.h"
    updateFile "VERSION = \\\"[^\\\"]\\+\\\"" "VERSION = \"$Version_new\"" "$Source/Source/Cli/version.h"
    echo "Source/Core/Core.cpp"
    updateFile "Version=\\\"[^\\\"]\\+\\\"" "Version=\"$Version_new\"" "$Source/Source/Core/Core.cpp"

    echo
    echo "Passage for version with dots..."
    index=0
    Files[((index++))]="Project/GNU/qctools.spec"
    Files[((index++))]="Project/GNU/qctools.dsc"
    Files[((index++))]="Project/GNU/PKGBUILD"
    Files[((index++))]="Project/OBS/deb7.dsc"
    Files[((index++))]="Project/OBS/deb7.debian/changelog"
    Files[((index++))]="Project/Mac/Info.plist"
    Files[((index++))]="Project/AppImage/Recipe.sh"
    Files[((index++))]="debian/changelog"
    Files[((index++))]="Source/Install/QCTools.nsi"
    Files[((index++))]="License.html"

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
    Files[((index++))]="Project/MSVC2013/GUI/QCTools.rc"
    Files[((index++))]="Project/MSVC2015/GUI/QCTools.rc"
    Files[((index++))]="Project/QtCreator/qctools-gui/QCTools.rc"
    Files[((index++))]="Project/QtCreator/qctools-cli/qcli.rc"

    for File in ${Files[@]}
    do
        echo "${Source}/${File}"
        updateFile $Version_old_major,$Version_old_minor,$Version_old_patch,$Version_old_build $Version_new_major,$Version_new_minor,$Version_new_patch,$Version_new_build "${Source}/${File}"
    done

    echo "Update Project/Mac/Info.plist"
    echo "Update Project/Mac/Make_xcarchive.sh"
    sed -i '/<key>CFBundleVersion<\/key>/ {n
                s/[0-9]\.[0-9]\.[0-9]*[0-9]/&@/g
                :i {
                    s/0@/1/g; s/1@/2/g
                    s/2@/3/g; s/3@/4/g
                    s/4@/5/g; s/5@/6/g
                    s/6@/7/g; s/7@/8/g
                    s/8@/9/g; s/9@/@0/g
                    t i }
                s/@/1/g }' "${Source}/Project/Mac/Info.plist" "${Source}/Project/Mac/Make_xcarchive.sh"

}
