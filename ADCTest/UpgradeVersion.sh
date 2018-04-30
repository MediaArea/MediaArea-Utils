# ADCTest/UpgradeVersion.sh
# Upgrade the version number of ADCTest

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function btask.UpgradeVersion.run () {

    local AT_source AT_files index

    if [ $(b.opt.get_opt --source-path) ]; then
        AT_source="$SDir"
    else
        getRepo $Repo "$WDir"
        AT_source="$WDir"/ADCTest
        echo
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$AT_source"
        git checkout $(sanitize_arg $(b.opt.get_opt --git-state))
        popd
    fi

    # Populate Version_old_* variables
    getOld "$AT_source/Project/version.txt"

    echo "Update version.txt"
    echo "${Version_new}" > "$AT_source/Project/version.txt"

    echo
    echo "Passage for version with dots..."
    index=0
    AT_files[((index++))]="Project/GNU/adctest.spec"
    AT_files[((index++))]="Project/GNU/adctest.dsc"
    AT_files[((index++))]="Project/GNU/PKGBUILD"
    AT_files[((index++))]="src/System/Prefs.h"
    AT_files[((index++))]="debian/changelog"


    for AT_file in ${AT_files[@]}
    do
        echo "${AT_source}/${AT_file}"
        updateFile "$Version_old_escaped" $Version_new "${AT_source}/${AT_file}"
    done
}
