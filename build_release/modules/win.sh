# build_release/modules/win.sh
# Utilities for Windows build

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

# Update the MediaArea-Utils-Binaries package and copy it into $DST
function win_copy_utils () {
    local DST="$1"
    local SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"

    if [ $# -lt 1 ] ; then
        return 2
    fi

    $SSHP "If (Test-Path \"$Win_working_dir\\MediaArea-Utils\\.git\") {
               Set-Location \"$Win_working_dir\\MediaArea-Utils\"
               git fetch --quiet origin
               git rebase --quiet origin/master

               Set-Location $DST
               git clone --quiet \"$Win_working_dir\\MediaArea-Utils\"
           } else {
               Set-Location $DST
               git clone --quiet \"https://github.com/MediaArea/MediaArea-Utils.git\"
           }"
}

# Update the MediaArea-Utils-Binaries package and copy it into $DST
function win_copy_binaries () {
    local DST="$1"
    local SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"

    if [ $# -lt 1 ] ; then
        return 2
    fi

    $SSHP "If (Test-Path \"$Win_working_dir\\MediaArea-Utils-Binaries\\.git\") {
               Set-Location \"$Win_working_dir\\MediaArea-Utils-Binaries\"
               git fetch --quiet origin
               git rebase --quiet origin/master

               Set-Location $DST
               git clone --quiet \"$Win_working_dir\\MediaArea-Utils-Binaries\"
           } else {
               Set-Location $DST
               git clone --quiet \"https://github.com/MediaArea/MediaArea-Utils-Binaries.git\"
           }"
}
