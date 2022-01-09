# RAWcooked/Release/UpgradeVersion.sh
# Upgrade the version number of RAWcooked

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
    Files[((index++))]="Project/GNU/sony9pin.spec"
    Files[((index++))]="Project/GNU/sony9pin.dsc"
    Files[((index++))]="Project/GNU/PKGBUILD"
    Files[((index++))]="debian/changelog"

    # Make the replacements
    for File in ${Files[@]}
    do
        echo "${Source}/${File}"
        updateFile "$Version_old_escaped" $Version_new "${Source}/${File}"
    done

    echo "${Source}/tools/sony9pin/sony9pin.cpp"
    updateFile "const char* version = \"$Version_old\";" "const char* version = \"$Version_new\";" "${Source}/tools/sony9pin/sony9pin.cpp"
}
