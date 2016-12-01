# QCTools/Release/BuildRelease.sh
# Build a release of QCTools

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _windows () {

    local SSHP Build_dir DLPath File

    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    Build_dir="build_$RANDOM"

    cd "$QC_tmp"

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

    # Get the sources
    scp -P $Win_SSH_port "prepare_source/archives/qctools_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"
           MediaArea-Utils-Binaries\\Windows\\7-Zip\7z x -y \"qctools_${Version_new}_AllInclusive.7z\" > \$null"
    sleep 3

    # Build
    echo "Compile QC for Windows..."
    
    $SSHP "$win_ps_utils

           # Save env
           \$OldEnv = Get-ChildItem Env:

           # Load env
           Load-VcVars x64

           Set-Location \"$Win_working_dir\\$Build_dir\"

           \$env:PATH=\"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Cygwin\\bin;\$env:PATH\"
           \$CodeSigningCertificatePass = Get-Content \"\$env:USERPROFILE\\CodeSigningCertificate.pass\"

           # Compile qctools 32 bits
           Remove-Item -Force -Recurse \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"
           Move-Item \"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.7-msvc2015_static\\5.7\\msvc2015_static\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"

           Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\BuildAllFromSource\"
           & .\\build.bat /static /target x86 2>&1

           If (Test-Path \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\StaticRelease\\QCTools.exe\") {

              # Sign binary
              signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d QCTools /du http://mediaarea.net \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\StaticRelease\\QCTools.exe\"

              # Make installer
              Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Source\\Install\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\NSIS\makensis /DSTATIC QCTools.nsi

              # Sign installer
              signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d QCTools /du http://mediaarea.net \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_Windows.exe\"

              # Make WithoutInstaller archive
              New-Item -Type \"directory\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_i386\"
              Set-Location  \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_i386\"

              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\StaticRelease\\QCTools.exe\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\History.txt\"
              Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\License.html\"
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_i386_WithoutInstaller.zip *

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_i386_DebugInfo.zip \`
                                                   \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\StaticRelease\\QCTools.pdb\"
           }

           # Compile qctools 64 bits
           Remove-Item -Force -Recurse \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"
           Start-Sleep 3

           If (Test-Path \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\") {
               Remove-Item -Force -Recurse \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"
               Start-Sleep 3
           }

           Move-Item \"$Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\Qt\\Qt5.7-msvc2015_static_64\\5.7\\msvc2015_static_64\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive/Qt\"

           Set-Location \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\BuildAllFromSource\"
           & .\\build.bat /static /target x64 2>&1

           If (Test-Path \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\StaticRelease\\QCTools.exe\") {
              # Sign binary
              signtool.exe sign /f \$env:USERPROFILE\\CodeSigningCertificate.p12 /p \$CodeSigningCertificatePass /fd sha256 /v /tr http://timestamp.geotrust.com/tsa /d QCTools /du http://mediaarea.net \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\StaticRelease\\QCTools.exe\"

               # Make WithoutInstaller archive
               New-Item -Type \"directory\" \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_x64\"
               Set-Location  \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\QCTools_${Version_new}_x64\"

               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\StaticRelease\\QCTools.exe\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\History.txt\"
               Copy-Item \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\License.html\"
               $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_x64_WithoutInstaller.zip *

              # Make DebugInfo archive
              $Win_working_dir\\$Build_dir\\MediaArea-Utils-Binaries\\Windows\\7-Zip\\7z a -r -tzip -mx9 ..\\QCTools_${Version_new}_Windows_x64_DebugInfo.zip \`
                                             \"$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools\\Project\\MSVC2015\\x64\\StaticRelease\\QCTools.pdb\"
            }

           # Restore env
           Load-Env(\$OldEnv)"

    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="$Win_working_dir\\$Build_dir\\qctools_AllInclusive\\qctools"

    File="QCTools_${Version_new}_Windows.exe"
    test -e "$QCB_dir/$File" && rm "$QCB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$QCB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_i386_WithoutInstaller.zip"
    test -e "$QCB_dir/$File" && rm "$QCB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$QCB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_i386_DebugInfo.zip"
    test -e "$QCB_dir/$File" && rm "$QCB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$QCB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_x64_WithoutInstaller.zip"
    test -e "$QCB_dir/$File" && rm "$QCB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$QCB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="QCTools_${Version_new}_Windows_x64_DebugInfo.zip"
    test -e "$QCB_dir/$File" && rm "$QCB_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$DLPath\\$File" \
                         "$QCB_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

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

function _mac () {

    local SSHP

    # SSH prefix
    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"

    cd "$QC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr qctools*"


    # Get the sources
    scp -P $Mac_SSH_port "prepare_source/archives/qctools_${Version_new}-1.tar.gz" "$Mac_SSH_user@$Mac_IP:$Mac_working_dir/qctools_${Version_new}-1.tar.gz"

    # Compile
    echo "Compile QC for mac..."
    $SSHP "cd \"$Mac_working_dir\"
           export PATH=\"/Users/mymac/Qt/5.3/clang_64/bin:\$PATH\"

           tar xf qctools_${Version_new}-1.tar.gz
           cd qctools/qctools

           ./Project/BuildAllFromSource/build

           test -e Project/QtCreator/QCTools.app/Contents/MacOS/QCTools || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg
           mv QCTools.dmg QCTools_${Version_new}_mac.dmg"

    echo "Retreive files"
    DLPath="$Mac_working_dir/qctools/qctools/Project/Mac"

    File="QCTools_${Version_new}_mac.dmg"
    scp -P $Mac_SSH_port "$Mac_SSH_user@$Mac_IP:$DLPath/$File" "$QCB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    # Cleaning
    echo "Cleaning..."
    $SSHP "cd \"$Mac_working_dir\"; rm -fr \"$Build_dir\""

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi

    return 0
}

function _obs () {

    local OBS_package="$OBS_project/QCTools"

    cd "$QC_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/qctools_${Version_new}-1.tar.gz $OBS_package/qctools_${Version_new}-1.tar.gz

    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/qctools.spec $OBS_package
    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/qctools.dsc $OBS_package
    cp prepare_source/QC/ALL/qctools_AllInclusive/qctools/Project/GNU/PKGBUILD $OBS_package

    update_dsc "$QC_tmp"/$OBS_package qctools_${Version_new}-1.tar.gz qctools.dsc
    update_PKGBUILD "$QC_tmp"/$OBS_package qctools_${Version_new}-1.tar.gz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    if [ ! $(b.opt.get_opt --rebuild) ] ; then
        _obs
    fi

    echo
    echo Launch in background the python script which check
    echo the build results and download the packages...
    echo
    echo The command line is:
    echo python Handle_OBS_results.py $* $OBS_project QCTools $Version_new "$QCB_dir"
    echo

    # To avoid "os.getcwd() failed: No such file or directory" if
    # $Clean_up is set (ie "$QC_tmp", the current directory, will
    # be deleted)
    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $* $OBS_project QCTools $Version_new "$QCB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

}

function btask.BuildRelease.run () {

    local UV_flags
    local QCB_dir="$Working_dir"/binary/qctools/$Sub_dir
    local QCS_dir="$Working_dir"/source/qctools/$Sub_dir
    local QC_tmp="$Working_dir"/tmp/qctools/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$QC_tmp"

    mkdir -p "$QCB_dir"

    if [ $(b.opt.get_opt --rebuild) ] ; then
        _linux --filter $(b.opt.get_opt --rebuild)
        exit 0
    fi

    mkdir -p "$QCS_dir"
    mkdir -p "$QC_tmp"

    cd "$QC_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$QC_tmp"/upgrade_version/qctools
    else
        pushd "$QC_tmp"/upgrade_version
        git clone "$Repo"

        # Sync with upstream
        cd qctools
        git fetch https://github.com/bavc/qctools.git

        git rebase FETCH_HEAD

        if [ $? -ne 0 ] ; then
            echo -e "Unable to automatically rebase the current branch on upstream" | mailx -s "[BR] Problem with QCTools" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
            git rebase --abort
        fi

        cd ..
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$QC_tmp"/upgrade_version/qctools
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $QC_tmp/upgrade_version/qctools/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p qc -n $Version_new $UV_flags -sp "$QC_tmp"/upgrade_version/qctools

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    find "$QCS_dir" -mindepth 1 -delete
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p qc -v $Version_new -wp "$QC_tmp"/prepare_source -sp "$QC_tmp"/upgrade_version/qctools  $PS_target -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
    fi

    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building QCTools" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi
    fi

    if [ "$Target" = "linux" ] || [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        mv "$QC_tmp"/prepare_source/archives/qctools_${Version_new}.* "$QCS_dir"
    fi

    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building QCTools" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$QC_tmp"/prepare_source/archives/qctools_${Version_new}_AllInclusive.7z "$QCS_dir"
    fi

    if $Clean_up; then
        rm -fr "$QC_tmp"
    fi
}
