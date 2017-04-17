# build_release/modules/win.sh
# Utilities for Windows build

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

# Utilities for PowerShell
win_ps_utils="
function Load-Env {
    param([Array]\$Env)

    \$Hash = @{}

    \$Env | ForEach-Object {
        \$Hash.add(\$_.Name, \$_.Value)
    }

    Get-ChildItem Env: | ForEach-Object {
        If (\$Hash.ContainsKey(\"\$_.Name\")) {
            Set-Content Env:\$(\$_.Name) \$Hash[\"\$_.Name\"]
        } Else {
            Remove-Item Env:\$(\$_.Name)
        }
    }
}

function Load-VcVars {
    param([ValidateSet(\"x86\", \"x64\")][String]\$Arch = \"x86\")

    If (Test-Path \"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\\vcvarsall.bat\") {
        cmd /c \"\`\"C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\\vcvarsall.bat\`\" \$Arch & set\" |
        ForEach {
            If (\$_ -Match \"(.*?)=(.*)\") {
                Set-Item -Force -Path \"ENV:\$(\$matches[1])\" -Value \"\$(\$matches[2])\"
            }
        }
    } Else {
        Write-Host \"Error: Visual Studio 2015 not installed\"
    }
}"

# Update the MediaArea-Utils-Binaries package and copy it into $DST
function win_copy_utils () {
    local DST="$1"
    local SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"

    if [ $# -lt 1 ] ; then
        return 2
    fi

    $SSHP "Set-Location $DST
           If (Test-Path \"$Win_working_dir\\MediaArea-Utils\\.git\") {
               git clone --depth 1 --quiet --reference \"$Win_working_dir\\MediaArea-Utils\" \"https://github.com/MediaArea/MediaArea-Utils.git\"
           } else {
               git clone --depth 1 --quiet \"https://github.com/MediaArea/MediaArea-Utils.git\"
           }"
}

# Update the MediaArea-Utils-Binaries package and copy it into $DST
function win_copy_binaries () {
    local DST="$1"
    local SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"

    if [ $# -lt 1 ] ; then
        return 2
    fi

    $SSHP "Set-Location $DST
           If (Test-Path \"$Win_working_dir\\MediaArea-Utils-Binaries\\.git\") {
               git clone --depth 1 --quiet --reference \"$Win_working_dir\\MediaArea-Utils-Binaries\" \"https://github.com/MediaArea/MediaArea-Utils-Binaries.git\"
           } else {
               git clone --depth 1 --quiet \"https://github.com/MediaArea/MediaArea-Utils-Binaries.git\"
           }"
}

# Try to remove directory tree
function win_rm_tree () {
    local DST="$1" Try=5
    local SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"

        $SSHP "\$Try=0
               While (Test-Path \"$DST\") {
                   Remove-Item -Force -Recurse \"$DST\"
                   \$Try++
                   If (\$Try -eq $Try) {
                       break
                   }
                   Start-Sleep -Seconds 3
               }
"
}
