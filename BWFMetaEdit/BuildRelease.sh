# BWFMetaEdit/Release/BuildRelease.sh
# Build a release of BWFMetaEdit

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {
    local DLPath File

    cd "$BM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr BWFMetaEdit_CLI*"

    echo
    echo "Compile BM CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/BWFMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/BWFMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf BWFMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz
           cd BWFMetaEdit_CLI_GNU_FromSource
           ./Project/Mac/BR_extension_CLI.sh
           test -x Project/GNU/CLI/bwfmetaedit || exit 1
           file Project/GNU/CLI/bwfmetaedit | grep \"Mach-O universal binary with 2 architectures\" || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh BWFMetaEdit cli $Version_new"

    DLPath="$Mac_working_dir/BWFMetaEdit_CLI_GNU_FromSource/Project/Mac"
    File="BWFMetaEdit_CLI_${Version_new}_Mac.dmg"
    test -e "$BMB_dir"/$File && rm "$BMB_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$BMB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac_gui () {
    local DLPath File

    cd "$BM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr BWFMetaEdit_GUI*"

    echo
    echo "Compile BM GUI for mac..."
    echo

        scp -P $Mac_SSH_port prepare_source/archives/BWFMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/BWFMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf BWFMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz
           cd BWFMetaEdit_GUI_GNU_FromSource

           export PATH=$Mac_qt_path/clang_64/bin:\$PATH
           ln -s $Mac_qt_path/clang_64 qt

           ./Project/Mac/BR_extension_GUI.sh
           test -x Project/GNU/GUI/bwfmetaedit-gui || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh BWFMetaEdit gui $Version_new"

    DLPath="$Mac_working_dir/BWFMetaEdit_GUI_GNU_FromSource/Project/Mac"
    File="BWFMetaEdit_GUI_${Version_new}_Mac.dmg"
    test -e "$BMG_dir"/$File && rm "$BMG_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$BMG_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac () {

    local SSHP

    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"

    _mac_cli
    _mac_gui

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi
}

function _windows () {

    local SSHP Build_dir DLPath File

    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    Build_dir="build_$RANDOM"

    cd "$BM_tmp"

    # Start the VM if needed
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ]; then
        if ! vm_start "$Virsh_uri" "$Win_VM_name" "$Win_IP" "$Win_SSH_port"; then
            MSG="ERROR: unable to start VM"
            print_e "$MSG"
            return 1
        fi
    fi

    # Test connection
    if ! $SSHP "exit"; then
        MSG="ERROR: unable to connect to host"
        print_e "$MSG"
        return 1
    fi
    sleep 3

    # Prepare build directory
    echo "Prepare build directory..."
    $SSHP "Set-Location \"$Win_working_dir\"; if(Test-Path \"$Build_dir\") { Remove-Item -Force -Recurse \"$Build_dir\" }"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\"; New-Item -Type \"directory\" \"$Build_dir\""
    sleep 3

    # Get the tools
    win_copy_binaries \"$Win_working_dir\\$Build_dir\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"
           Move-Item \"MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.7-msvc2015_static\\5.7\\msvc2015_static\" \"Qt\"
           Move-Item \"MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.7-msvc2015_static_64\\5.7\\msvc2015_static_64\" \"Qt64\""
    sleep 3

    # Get the sources
    scp -P $Win_SSH_port "prepare_source/archives/bwfmetaedit_${Version_new}.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"; MediaArea-Utils-Binaries\\Windows\\7-Zip\7z x -y bwfmetaedit_${Version_new}.7z > \$null"
    sleep 3

    # Build
    echo "Compile BM for Windows..."


    $SSHP "$win_ps_utils

           # Save env
           \$OldEnv = Get-ChildItem Env:

           # Load env
           Load-VcVars x64

           # Get password for signing
           \$CodeSigningCertificatePass = Get-Content \"\$env:USERPROFILE\\CodeSigningCertificate.pass\"

           #
           # Compile CLI
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\CLI\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\bwfmetaedit.exe\") -And (Test-Path \"x64\\Release\\bwfmetaedit.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d BWFMetaEdit /du http://mediaarea.net \"Win32\\Release\\bwfmetaedit.exe\" \"x64\\Release\\bwfmetaedit.exe\"

               # Make archives
               Set-Location \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Release\"
               cmd /s /c \"Release_CLI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_CLI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 BWF_MetaEdit_CLI_Windows_i386_DebugInfo.zip \`
                                                 \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\CLI\\Win32\\Release\\bwfmetaedit.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 BWF_MetaEdit_CLI_Windows_x64_DebugInfo.zip \`
                                                  \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\CLI\\x64\\Release\\bwfmetaedit.pdb\"
           }


           #
           # Compile GUI
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\GUI\"
           cmd /s /c \"qt_update.bat 2>&1\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\BWF_MetaEdit_GUI.exe\") -And (Test-Path \"x64\\Release\\BWF_MetaEdit_GUI.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d BWFMetaEdit /du http://mediaarea.net \"Win32\\Release\\BWF_MetaEdit_GUI.exe\" \"x64\\Release\\BWF_MetaEdit_GUI.exe\"

               # Make installers and archives
               Set-Location \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Release\"
               cmd /s /c \"Release_GUI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_GUI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 BWF_MetaEdit_GUI_Windows_i386_DebugInfo.zip \`
                                            \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\GUI\\Win32\\Release\\BWF_MetaEdit_GUI.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 BWF_MetaEdit_GUI_Windows_x64_DebugInfo.zip \`
                                             \"$Win_working_dir\\$Build_dir\\bwfmetaedit\\Project\\MSVC2015\\GUI\\x64\\Release\\BWF_MetaEdit_GUI.pdb\"

               # Sign installers
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d DVAnalyzer /du http://mediaarea.net \"BWF_MetaEdit_GUI_${Version_new}_Windows_i386.exe\" \"BWF_MetaEdit_GUI_${Version_new}_Windows_x64.exe\"
           }

           # Restore env
           Load-Env(\$OldEnv)"
    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="$Win_working_dir\\$Build_dir\\bwfmetaedit\\Release"

    File="BWF_MetaEdit_CLI_${Version_new}_Windows_i386.zip"
    test -e "$BMB_dir/$File" && rm "$BMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_CLI_Windows_i386.zip" \
                         "$BMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_CLI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$BMB_dir/$File" && rm "$BMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_CLI_Windows_i386_DebugInfo.zip" \
                         "$BMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_CLI_${Version_new}_Windows_x64.zip"
    test -e "$BMB_dir/$File" && rm "$BMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_CLI_Windows_x64.zip" \
                         "$BMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_CLI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$BMB_dir/$File" && rm "$BMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_CLI_Windows_x64_DebugInfo.zip" \
                         "$BMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_GUI_${Version_new}_Windows_i386_WithoutInstaller.zip"
    test -e "$BMG_dir/$File" && rm "$BMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_GUI_Windows_i386_WithoutInstaller.zip" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_GUI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$MMG_dir/$File" && rm "$MMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_GUI_Windows_i386_DebugInfo.zip" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_GUI_${Version_new}_Windows_x64_WithoutInstaller.zip"
    test -e "$BMG_dir/$File" && rm "$BMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_GUI_Windows_x64_WithoutInstaller.zip" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3


    File="BWF_MetaEdit_GUI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$BMG_dir/$File" && rm "$BMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\BWF_MetaEdit_GUI_Windows_x64_DebugInfo.zip" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_GUI_${Version_new}_Windows_i386.exe"
    test -e "$BMG_dir/$File" && rm "$BMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="BWF_MetaEdit_GUI_${Version_new}_Windows_x64.exe"
    test -e "$BMG_dir/$File" && rm "$BMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$BMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    # Cleaning
    echo "Cleaning..."

    win_rm_tree "$Win_working_dir\\$Build_dir"

    # Stop the VM
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ]; then
        vm_stop "$Virsh_URI" "$Win_VM_name"
    fi

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi

    return 0
}

function _obs () {

    local OBS_package="$OBS_project/BWFMetaEdit"

    cd "$BM_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/bwfmetaedit_${Version_new}.tar.gz $OBS_package/bwfmetaedit_${Version_new}-1.tar.gz

    cp prepare_source/BM/bwfmetaedit/Project/GNU/bwfmetaedit.spec $OBS_package
    cp prepare_source/BM/bwfmetaedit/Project/GNU/bwfmetaedit.dsc $OBS_package
    cp prepare_source/BM/bwfmetaedit/Project/GNU/PKGBUILD $OBS_package

    update_dsc "$BM_tmp"/$OBS_package bwfmetaedit_${Version_new}-1.tar.gz bwfmetaedit.dsc
    update_PKGBUILD "$BM_tmp"/$OBS_package bwfmetaedit_${Version_new}-1.tar.gz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    _obs

    echo
    echo Launch in background the python script which check
    echo the build results and download the packages...
    echo
    echo The command line is:
    echo python Handle_OBS_results.py $Filter $OBS_project BWFMetaEdit $Version_new "$BMB_dir" "$BMG_dir"
    echo

    # To avoid "os.getcwd() failed: No such file or directory" if
    # $Clean_up is set (ie "$BM_tmp", the current directory, will
    # be deleted)
    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $Filter $OBS_project BWFMetaEdit $Version_new "$BMB_dir" "$BMG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

}

function btask.BuildRelease.run () {

    local UV_flags
    local BMB_dir="$Working_dir"/binary/bwfmetaedit/$Sub_dir
    local BMG_dir="$Working_dir"/binary/bwfmetaedit-gui/$Sub_dir
    local BMS_dir="$Working_dir"/source/bwfmetaedit/$Sub_dir
    local BM_tmp="$Working_dir"/tmp/bwfmetaedit/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$BM_tmp"

    mkdir -p "$BMB_dir"
    mkdir -p "$BMG_dir"

    mkdir -p "$BMS_dir"
    mkdir -p "$BM_tmp"

    cd "$BM_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$BM_tmp"/upgrade_version/BWF_MetaEdit
    else
        pushd "$BM_tmp"/upgrade_version
        git clone "$Repo" BWF_MetaEdit
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$BM_tmp"/upgrade_version/BWF_MetaEdit
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $BM_tmp/upgrade_version/BWF_MetaEdit/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p bm -n $Version_new $UV_flags -sp "$BM_tmp"/upgrade_version/BWF_MetaEdit

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    find "$BMS_dir" -mindepth 1 -delete
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p bm -v $Version_new -wp "$BM_tmp"/prepare_source -sp "$BM_tmp"/upgrade_version/BWF_MetaEdit -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$BM_tmp"/prepare_source/archives/bwfmetaedit_${Version_new}.tar.* "$BMS_dir"
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building BWFMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$BM_tmp"/prepare_source/archives/BWFMetaEdit_CLI_${Version_new}_GNU_FromSource.* "$BMB_dir"
        mv "$BM_tmp"/prepare_source/archives/BWFMetaEdit_GUI_${Version_new}_GNU_FromSource.* "$BMG_dir"
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building BWFMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$BM_tmp"/prepare_source/archives/bwfmetaedit_${Version_new}.7z "$BMS_dir"
    fi

    if $Clean_up; then
        rm -fr "$BM_tmp"
    fi

}
