# dvanalyzer/Release/BuildRelease.sh
# Build a release of dvanalyzer

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {
    local DLPath File

    cd "$DA_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr DVAnalyzer_CLI*"

    echo
    echo "Compile DA CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/DVAnalyzer_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/DVAnalyzer_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf DVAnalyzer_CLI_${Version_new}_GNU_FromSource.tar.xz
           cd DVAnalyzer_CLI_GNU_FromSource
           AVPS_DV_Analyzer/Project/Mac/BR_extension_CLI.sh
           test -x AVPS_DV_Analyzer/Project/GNU/CLI/dvanalyzer || exit 1
           file AVPS_DV_Analyzer/Project/GNU/CLI/dvanalyzer | grep \"Mach-O universal binary with 2 architectures\" || exit 1
           $Key_chain
           cd AVPS_DV_Analyzer/Project/Mac
           ./mkdmg.sh DVAnalyzer cli $Version_new"

    DLPath="$Mac_working_dir/DVAnalyzer_CLI_GNU_FromSource/AVPS_DV_Analyzer/Project/Mac"
    File="DVAnalyzer_CLI_${Version_new}_Mac.dmg"
    test -e "$DAB_dir"/$File && rm "$DAB_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$DAB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac_gui () {
    local DLPath File

    cd "$DA_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr DVAnalyzer_GUI*"

    echo
    echo "Compile DA GUI for mac..."
    echo

        scp -P $Mac_SSH_port prepare_source/archives/DVAnalyzer_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/DVAnalyzer_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf DVAnalyzer_GUI_${Version_new}_GNU_FromSource.tar.xz
           cd DVAnalyzer_GUI_GNU_FromSource

           export PATH=$Mac_qt_path/clang_64/bin:\$PATH
           ln -s $Mac_qt_path/clang_64 qt

           AVPS_DV_Analyzer/Project/Mac/BR_extension_GUI.sh
           test -x AVPS_DV_Analyzer/Project/GNU/GUI/dvanalyzer-gui || exit 1
           $Key_chain
           cd AVPS_DV_Analyzer/Project/Mac
           ./mkdmg.sh DVAnalyzer gui $Version_new"

    DLPath="$Mac_working_dir/DVAnalyzer_GUI_GNU_FromSource/AVPS_DV_Analyzer/Project/Mac"
    File="DVAnalyzer_GUI_${Version_new}_Mac.dmg"
    test -e "$DAG_dir"/$File && rm "$DAG_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$DAG_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
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

    cd "$DA_tmp"

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
    scp -P $Win_SSH_port "prepare_source/archives/dvanalyzer_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"; MediaArea-Utils-Binaries\\Windows\\7-Zip\7z x -y dvanalyzer_${Version_new}_AllInclusive.7z > \$null"
    sleep 3

    # Build
    echo "Compile DA for Windows..."

    $SSHP "$win_ps_utils

           # Save env
           \$OldEnv = Get-ChildItem Env:

           # Get password for signing
           \$CodeSigningCertificatePass = Get-Content \"\$env:USERPROFILE\\CodeSigningCertificate.pass\"

           # Prepare zlib
           Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\zlib\\contrib\\masmx86\"
           (Get-Content \"bld_ml32.bat\") | ForEach-Object { \$_ -creplace \"ml /coff\", \"ml /safeseh /coff\" } | Set-Content \"bld_ml32.bat\"
           # Load 32 bits env
           Load-VcVars x86
           cmd /s /c \"bld_ml32.bat 2>&1\"
           Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\zlib\\contrib\\masmx64\"
           # Load 64 bits env
           Load-VcVars x64
           cmd /s /c \"bld_ml64.bat 2>&1\"

           #
           # Compile MediaInfoLib
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\MediaInfoLib\\Project\\MSVC2015\\Library\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           #
           # Compile CLI
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\CLI\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\dvanalyzer.exe\") -And (Test-Path \"x64\\Release\\dvanalyzer.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d DVAnalyzer /du http://mediaarea.net \"Win32\\Release\\dvanalyzer.exe\" \"x64\\Release\\dvanalyzer.exe\"

               # Make archives
               Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Release\"
               cmd /s /c \"Release_CLI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_CLI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVPS_DV_Analyzer_CLI_Windows_i386_DebugInfo.zip \`
              \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\CLI\\Win32\\Release\\AVPS_DV_Analyzer_CLI.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVPS_DV_Analyzer_CLI_Windows_x64_DebugInfo.zip \`
               \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\CLI\\x64\\Release\\AVPS_DV_Analyzer_CLI.pdb\"
           }

           #
           # Compile GUI
           #

           Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\GUI\"
           cmd /s /c \"qt_update.bat 2>&1\"
           MSBuild /p:Configuration=Release\`;Platform=Win32
           MSBuild /p:Configuration=Release\`;Platform=x64

           If ((Test-Path \"Win32\\Release\\AVPS_DV_Analyzer_GUI.exe\") -And (Test-Path \"x64\\Release\\AVPS_DV_Analyzer_GUI.exe\")) {
               # Sign binaries
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d DVAnalyzer /du http://mediaarea.net \"Win32\\Release\\AVPS_DV_Analyzer_GUI.exe\" \"x64\\Release\\AVPS_DV_Analyzer_GUI.exe\"

               # Make installers and archives
               Set-Location \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Release\"
               cmd /s /c \"Release_GUI_Windows_i386.bat 2>&1\"
               cmd /s /c \"Release_GUI_Windows_x64.bat 2>&1\"

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVPS_DV_Analyzer_GUI_Windows_i386_DebugInfo.zip \`
              \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\GUI\\Win32\\Release\\AVPS_DV_Analyzer_GUI.pdb\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 AVPS_DV_Analyzer_GUI_Windows_x64_DebugInfo.zip \`
               \"$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Project\\MSVC2015\\GUI\\x64\\Release\\AVPS_DV_Analyzer_GUI.pdb\"

               # Sign installers
               signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.comodoca.com/?td=sha256 /d DVAnalyzer /du http://mediaarea.net \"AVPS_DV_Analyzer_GUI_${Version_new}_Windows_i386.exe\" \"AVPS_DV_Analyzer_GUI_${Version_new}_Windows_x64.exe\"
           }

           # Restore env
           Load-Env(\$OldEnv)"
    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="$Win_working_dir\\$Build_dir\\dvanalyzer_AllInclusive\\AVPS_DV_Analyzer\\Release"

    File="AVPS_DV_Analyzer_CLI_${Version_new}_Windows_i386.zip"
    test -e "$DAB_dir/$File" && rm "$DAB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_CLI_Windows_i386.zip" \
                         "$DAB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_CLI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$DAB_dir/$File" && rm "$DAB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_CLI_Windows_i386_DebugInfo.zip" \
                         "$DAB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_CLI_${Version_new}_Windows_x64.zip"
    test -e "$DAB_dir/$File" && rm "$DAB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_CLI_Windows_x64.zip" \
                         "$DAB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_CLI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$DAB_dir/$File" && rm "$DAB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_CLI_Windows_x64_DebugInfo.zip" \
                         "$DAB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_i386_WithoutInstaller.7z"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_GUI_Windows_i386_WithoutInstaller.7z" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_GUI_Windows_i386_DebugInfo.zip" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3


    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_x64_WithoutInstaller.7z"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_GUI_Windows_x64_WithoutInstaller.7z" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\AVPS_DV_Analyzer_GUI_Windows_x64_DebugInfo.zip" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_i386.exe"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="AVPS_DV_Analyzer_GUI_${Version_new}_Windows_x64.exe"
    test -e "$DAG_dir/$File" && rm "$DAG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$DAG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

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

    local OBS_package="$OBS_project/DVAnalyzer"

    cd "$DA_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/dvanalyzer_${Version_new}.tar.gz $OBS_package/dvanalyzer_${Version_new}-1.tar.gz

    cp prepare_source/DA/AVPS_DV_Analyzer/Project/GNU/dvanalyzer.spec $OBS_package
    cp prepare_source/DA/AVPS_DV_Analyzer/Project/GNU/dvanalyzer.dsc $OBS_package
    cp prepare_source/DA/AVPS_DV_Analyzer/Project/GNU/PKGBUILD $OBS_package

    update_dsc "$DA_tmp"/$OBS_package dvanalyzer_${Version_new}-1.tar.gz dvanalyzer.dsc
    update_PKGBUILD "$DA_tmp"/$OBS_package dvanalyzer_${Version_new}-1.tar.gz PKGBUILD

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
        echo python Handle_OBS_results.py $Filter $OBS_project DVAnalyzer $Version_new "$DAB_dir" "$DAG_dir"
        echo

        # To avoid "os.getcwd() failed: No such file or directory" if
        # $Clean_up is set (ie "$DA_tmp", the current directory, will
        # be deleted)
        cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
        python Handle_OBS_results.py $Filter $OBS_project DVAnalyzer $Version_new "$DAB_dir" "$DAG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    else
        echo "#!/bin/bash" > "$WORKSPACE/STAGE"
        echo "python Handle_OBS_results.py $Filter $OBS_project DVAnalyzer $Version_new \"$DAB_dir\" \"$DAG_dir\"" > "$WORKSPACE/STAGE"
        chmod +x "$WORKSPACE/STAGE"
    fi
}

function btask.BuildRelease.run () {

    local UV_flags
    local DAB_dir="$Working_dir"/binary/dvanalyzer/$Sub_dir
    local DAG_dir="$Working_dir"/binary/dvanalyzer-gui/$Sub_dir
    local DAS_dir="$Working_dir"/source/dvanalyzer/$Sub_dir
    local DA_tmp="$Working_dir"/tmp/dvanalyzer/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$DA_tmp"

    mkdir -p "$DAB_dir"
    mkdir -p "$DAG_dir"

    mkdir -p "$DAS_dir"
    mkdir -p "$DA_tmp"

    cd "$DA_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$DA_tmp"/upgrade_version/DV_Analyzer
    else
        pushd "$DA_tmp"/upgrade_version
        git clone "$Repo" DV_Analyzer
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$DA_tmp"/upgrade_version/DV_Analyzer
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $DA_tmp/upgrade_version/DV_Analyzer/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p da -n $Version_new $UV_flags -sp "$DA_tmp"/upgrade_version/DV_Analyzer

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$DAS_dir" -name 'dvanalyzer_*.tar.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        find "$DAB_dir" "$DAG_dir" -name 'DVAnalyzer_*_GNU_FromSource.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        find "$DAS_dir" -name 'dvanalyzer_*_AllInclusive.7z' -mindepth 1 -delete
    fi

    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p da -v $Version_new -wp "$DA_tmp"/prepare_source -sp "$DA_tmp"/upgrade_version/DV_Analyzer $PS_target -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$DA_tmp"/prepare_source/archives/dvanalyzer_${Version_new}.* "$DAS_dir"
    fi

    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building DVAnalyzer" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$DA_tmp"/prepare_source/archives/DVAnalyzer_CLI_${Version_new}_GNU_FromSource.* "$DAB_dir"
        mv "$DA_tmp"/prepare_source/archives/DVAnalyzer_GUI_${Version_new}_GNU_FromSource.* "$DAG_dir"
    fi

    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building DVAnalyzer" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$DA_tmp"/prepare_source/archives/dvanalyzer_${Version_new}_AllInclusive.7z "$DAS_dir"
    fi

    if $Clean_up; then
        rm -fr "$DA_tmp"
    fi

}
