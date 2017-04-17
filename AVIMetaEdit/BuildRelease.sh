# aviMetaEdit/Release/BuildRelease.sh
# Build a release of aviMetaEdit

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {
    local DLPath File

    cd "$AM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr AVIMetaEdit_CLI*"

    echo
    echo "Compile AM CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/AVIMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/AVIMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf AVIMetaEdit_CLI_${Version_new}_GNU_FromSource.tar.xz
           cd AVIMetaEdit_CLI_GNU_FromSource
           ./Project/Mac/BR_extension_CLI.sh
           test -x Project/GNU/CLI/avimetaedit || exit 1
           file Project/GNU/CLI/avimetaedit | grep \"Mach-O universal binary with 2 architectures\" || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh AVIMetaEdit cli $Version_new"

    DLPath="$Mac_working_dir/AVIMetaEdit_CLI_GNU_FromSource/Project/Mac"
    File="AVIMetaEdit_CLI_${Version_new}_Mac.dmg"
    test -e "$AMB_dir"/$File && rm "$AMB_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$AMB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac_gui () {
    local DLPath File

    cd "$AM_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr AVIMetaEdit_GUI*"

    echo
    echo "Compile AM GUI for mac..."
    echo

        scp -P $Mac_SSH_port prepare_source/archives/AVIMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/AVIMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf AVIMetaEdit_GUI_${Version_new}_GNU_FromSource.tar.xz
           cd AVIMetaEdit_GUI_GNU_FromSource

           export PATH=$Mac_qt_path/clang_64/bin:\$PATH
           ln -s $Mac_qt_path/clang_64 qt

           ./Project/Mac/BR_extension_GUI.sh
           test -x Project/GNU/GUI/avimetaedit-gui || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh AVIMetaEdit gui $Version_new"

    DLPath="$Mac_working_dir/AVIMetaEdit_GUI_GNU_FromSource/Project/Mac"
    File="AVIMetaEdit_GUI_${Version_new}_Mac.dmg"
    test -e "$AMG_dir"/$File && rm "$AMG_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$AMG_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
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

    cd "$AM_tmp"

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
    scp -P $Win_SSH_port "prepare_source/archives/avimetaedit_${Version_new}.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"; MediaArea-Utils-Binaries\\Windows\\7-Zip\7z x -y avimetaedit_${Version_new}.7z > \$null"
    sleep 3

    # Build
    echo "Compile AM for Windows..."

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

           Set-Location \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\CLI\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\avimetaedit.exe\") -And (Test-Path \"x64\\Release\\avimetaedit.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d AVIMetaEdit /du http://mediaarea.net \"Win32\\Release\\avimetaedit.exe\" \"x64\\Release\\avimetaedit.exe\"

               # Make archives
               Set-Location \"$Win_working_dir\\$Build_dir\\avimetaedit\\Release\"
               cmd /s /c \"Release_CLI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_CLI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVI_MetaEdit_CLI_Windows_i386_DebugInfo.zip \`
                                                 \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\CLI\\Win32\\Release\\avimetaedit.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVI_MetaEdit_CLI_Windows_x64_DebugInfo.zip \`
                                                  \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\CLI\\x64\\Release\\avimetaedit.pdb\"
           }


           #
           # Compile GUI
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\GUI\"
           cmd /s /c \"qt_update.bat 2>&1\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\AVI_MetaEdit_GUI.exe\") -And (Test-Path \"x64\\Release\\AVI_MetaEdit_GUI.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d AVIMetaEdit /du http://mediaarea.net \"Win32\\Release\\AVI_MetaEdit_GUI.exe\" \"x64\\Release\\AVI_MetaEdit_GUI.exe\"

               # Make installers and archives
               Set-Location \"$Win_working_dir\\$Build_dir\\avimetaedit\\Release\"
               cmd /s /c \"Release_GUI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_GUI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVI_MetaEdit_GUI_Windows_i386_DebugInfo.zip \`
                                            \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\GUI\\Win32\\Release\\AVI_MetaEdit_GUI.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVI_MetaEdit_GUI_Windows_x64_DebugInfo.zip \`
                                             \"$Win_working_dir\\$Build_dir\\avimetaedit\\Project\\MSVC2015\\GUI\\x64\\Release\\AVI_MetaEdit_GUI.pdb\"

               # Sign installers
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d DVAnalyzer /du http://mediaarea.net \"AVI_MetaEdit_GUI_${Version_new}_Windows_i386.exe\" \"AVI_MetaEdit_GUI_${Version_new}_Windows_x64.exe\"
           }

           # Restore env
           Load-Env(\$OldEnv)
"
    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="$Win_working_dir\\$Build_dir\\avimetaedit\\Release"

    File="AVI_MetaEdit_CLI_${Version_new}_Windows_i386.zip"
    test -e "$AMB_dir/$File" && rm "$AMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_CLI_Windows_i386.zip" \
                         "$AMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_CLI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_CLI_Windows_i386_DebugInfo.zip" \
                         "$AMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_CLI_${Version_new}_Windows_x64.zip"
    test -e "$AMB_dir/$File" && rm "$AMB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_CLI_Windows_x64.zip" \
                         "$AMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_CLI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_CLI_Windows_x64_DebugInfo.zip" \
                         "$AMB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_i386_WithoutInstaller.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_GUI_Windows_i386_WithoutInstaller.zip" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_GUI_Windows_i386_DebugInfo.zip" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_x64_WithoutInstaller.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_GUI_Windows_x64_WithoutInstaller.zip" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVI_MetaEdit_GUI_Windows_x64_DebugInfo.zip" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_i386.exe"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVI_MetaEdit_GUI_${Version_new}_Windows_x64.exe"
    test -e "$AMG_dir/$File" && rm "$AMG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$AMG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

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

    local OBS_package="$OBS_project/AVIMetaEdit"

    cd "$AM_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/obs/* $OBS_package

    cd $OBS_package
    osc addremove *
    osc commit -n
}

function _linux () {

        _obs

    if ! b.opt.has_flag? --jenkins ; then
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
        echo The command line is:
        echo python Handle_OBS_results.py $Filter $OBS_project AVIMetaEdit $Version_new "$AMB_dir" "$AMG_dir"
        echo

        # To avoid "os.getcwd() failed: No such file or directory" if
        # $Clean_up is set (ie "$AM_tmp", the current directory, will
        # be deleted)
        cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
        python Handle_OBS_results.py $Filter $OBS_project AVIMetaEdit $Version_new "$AMB_dir" "$AMG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    else
        echo "#!/bin/bash" > "$WORKSPACE/STAGE"
        echo "python Handle_OBS_results.py $Filter $OBS_project AVIMetaEdit $Version_new \"$AMB_dir\" \"$AMG_dir\"" > "$WORKSPACE/STAGE"
        chmod +x "$WORKSPACE/STAGE"
    fi

}

function btask.BuildRelease.run () {

    local UV_flags
    local AMB_dir="$Working_dir"/binary/avimetaedit/$Sub_dir
    local AMG_dir="$Working_dir"/binary/avimetaedit-gui/$Sub_dir
    local AMS_dir="$Working_dir"/source/avimetaedit/$Sub_dir
    local AM_tmp="$Working_dir"/tmp/avimetaedit/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$AM_tmp"

    mkdir -p "$AMB_dir"
    mkdir -p "$AMG_dir"

    mkdir -p "$AMS_dir"
    mkdir -p "$AM_tmp"

    cd "$AM_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$AM_tmp"/upgrade_version/AVI_MetaEdit
    else
        pushd "$AM_tmp"/upgrade_version
        git clone "$Repo" AVI_MetaEdit
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$AM_tmp"/upgrade_version/AVI_MetaEdit
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $AM_tmp/upgrade_version/AVI_MetaEdit/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p am -n $Version_new $UV_flags -sp "$AM_tmp"/upgrade_version/AVI_MetaEdit

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$AMS_dir" -name 'avimetaedit_*.tar.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        find "$AMB_dir" "$AMG_dir" -name 'AVIMetaEdit_*_GNU_FromSource.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        find "$AMS_dir" -name 'avimetaedit_*.7z' -mindepth 1 -delete
    fi

    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p am -v $Version_new -wp "$AM_tmp"/prepare_source -sp "$AM_tmp"/upgrade_version/AVI_MetaEdit -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$AM_tmp"/prepare_source/archives/avimetaedit_${Version_new}.tar.* "$AMS_dir"
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building AVIMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$AM_tmp"/prepare_source/archives/AVIMetaEdit_CLI_${Version_new}_GNU_FromSource.* "$AMB_dir"
        mv "$AM_tmp"/prepare_source/archives/AVIMetaEdit_GUI_${Version_new}_GNU_FromSource.* "$AMG_dir"
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building AVIMetaEdit" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$AM_tmp"/prepare_source/archives/avimetaedit_${Version_new}.7z "$AMS_dir"
    fi

    if $Clean_up; then
        rm -fr "$AM_tmp"
    fi

}
