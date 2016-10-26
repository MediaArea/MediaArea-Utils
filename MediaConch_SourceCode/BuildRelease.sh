# MediaConch_SourceCode/Release/BuildRelease.sh
# Build a release of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaConch_CLI*"

    echo
    echo "Compile MC CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_CLI_GNU_FromSource ;
            MediaConch/Project/Mac/BR_extension_CLI.sh ;
            $Key_chain ;
            cd MediaConch/Project/Mac ;
            ./Make_MC_dmg.sh cli $Version_new"

    test -e "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg && rm "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_CLI_${Version_new}_Mac.dmg "$MCC_dir"

}

function _mac_server () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaConch_Server*"

    echo
    echo "Compile MC server for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaConch_Server_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_Server_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaConch_Server_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_Server_GNU_FromSource ;
            MediaConch/Project/Mac/BR_extension_Server.sh ;
            $Key_chain ;
            cd MediaConch/Project/Mac ;
            ./Make_MC_dmg.sh server $Version_new"

    test -e "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg && rm "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_Server_GNU_FromSource/MediaConch/Project/Mac/MediaConch_Server_${Version_new}_Mac.dmg "$MCD_dir"

}

function _mac_gui () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaConch_GUI*"

    echo
    echo "Compile MC GUI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_GUI_GNU_FromSource ;
            MediaConch/Project/Mac/BR_extension_GUI.sh ;
            $Key_chain ;
            cd MediaConch/Project/Mac ;
            ./Make_MC_dmg.sh gui $Version_new"

    test -e "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg && rm "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_GUI_${Version_new}_Mac.dmg "$MCG_dir"

}

function _mac () {

    # This function test the success of the compilation by testing
    # the size. If fail, retry to compile up to 3 times.

    local SSHP NbTry Try

    # SSH prefix
    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"
    NbTry=3

    cd "$MC_tmp"

    Try=0
    touch "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg
    until [ 0`stat -c %s "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg 2>/dev/null` -gt 2000000 ] || [ $Try -eq $NbTry ]; do
        _mac_cli
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg
    until [ 0`stat -c %s "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg 2>/dev/null` -gt 3000000 ] || [ $Try -eq $NbTry ]; do
        _mac_server
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg
    until [ 0`stat -c %s "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg 2>/dev/null` -gt 10000000 ] || [ $Try -eq $NbTry ]; do
        _mac_gui
        Try=$(($Try + 1))
    done

    # Send a mail on errors

    # Test mediaconch executable
    $SSHP "$Mac_working_dir/MediaConch_CLI_GNU_FromSource/MediaConch/Project/GNU/CLI/mediaconch --version" &>/dev/null
    if [ $? -ne 0 ] ; then
        MSG="${MSG}Error $? when trying execute mediaconch.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            PJ="${PJ} -a $Log/mac-cli.log.xz"
        fi
    fi

    # If the CLI dmg is less than 3 Mo
    if [ 0`stat -c %s "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg 2>/dev/null` -lt 3000000 ]; then
        MSG="${MSG}The CLI dmg is less than 3 Mo.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            PJ="${PJ} -a $Log/mac-cli.log.xz"
        fi
    fi

    # If the server dmg is less than 3 Mo
    if [ 0`stat -c %s "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg 2>/dev/null` -lt 3000000 ]; then
        MSG="${MSG}The server dmg is less than 3 Mo.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-server.log
            PJ="${PJ} -a $Log/mac-server.log.xz"
        fi
    fi

    # If the GUI dmg is less than 20 Mo
    if [ 0`stat -c %s "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg 2>/dev/null` -lt 20000000 ]; then
        MSG="${MSG}The GUI dmg is less than 20 Mo.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-gui.log
            PJ="${PJ} -a $Log/mac-gui.log.xz"
        fi
    fi

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

    cd "$MC_tmp"

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
    win_copy_utils \"$Win_working_dir\\$Build_dir\"
    sleep 3
    win_copy_binaries \"$Win_working_dir\\$Build_dir\"
    sleep 3

    # Get the sources
    scp -P $Win_SSH_port "prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    # Build
    echo "Compile MC for Windows..."

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\\MediaArea-Utils\\build_release\"; cmd /c \"BuildRelease.bat MC /archive 2>&1\""
    sleep 3

    # Test MediaConch executables
    $SSHP "$Win_working_dir\\$Build_dir\\mediaconch_AllInclusive\\MediaConch\\Project\\MSVC2015\\Win32\\Release\\MediaConch.exe --version" &>/dev/null || \
           MSG="${MSG}Error $? when trying execute MediaConch.exe (Win32).\n"

    $SSHP "$Win_working_dir\\$Build_dir\\mediaconch_AllInclusive\\MediaCOnch\\Project\\MSVC2015\\x64\\Release\\MediaConch.exe --version" &>/dev/null || \
           MSG="${MSG}Error $? when trying execute MediaConch.exe (x64).\n"

    # Retrieve files
    echo "Retreive files"
    DLPath="MediaArea-Utils\\build_release\\Release\\download\\binary"

    File="MediaConch_CLI_${Version_new}_Windows_i386.zip"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch\\${Version_new%.????????}\\MediaConch_CLI_${Version_new%.????????}_Windows_i386.zip" \
                         "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_CLI_${Version_new}_Windows_x64.zip"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch\\${Version_new%.????????}\\MediaConch_CLI_${Version_new%.????????}_Windows_x64.zip" \
                         "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows_i386_WithoutInstaller.7z"
    test -e "$MCG_dir/$File" && rm "$MCG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows_i386_WithoutInstaller.7z" \
                         "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows_x64_WithoutInstaller.7z"
    test -e "$MCG_dir/$File" && rm "$MCG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows_x64_WithoutInstaller.7z" \
                         "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows.exe"
    test -e "$MCG_dir/$File" && rm "$MCG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows.exe" \
                         "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_Server_${Version_new}_Windows_i386.zip"
    test -e "$MCD_dir/$File" && rm "$MCD_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-server\\${Version_new%.????????}\\MediaConch_Server_${Version_new%.????????}_Windows_i386.zip" \
                         "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_Server_${Version_new}_Windows_x64.zip"
    test -e "$MCD_dir/$File" && rm "$MCD_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-server\\${Version_new%.????????}\\MediaConch_Server_${Version_new%.????????}_Windows_x64.zip" \
                         "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

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

function _linux_images () {

    local SSHP Build_dir File Container_name

    SSHP="ssh -x -p $Ubuntu_SSH_port $Ubuntu_SSH_user@$Ubuntu_IP"
    Build_dir="build_$RANDOM"
    Container_name="$RANDOM"

    cd "$MC_tmp"

    # Start the VM if needed
    if [ -n "$Ubuntu_VM_name" ] && [ -n "$Virsh_uri" ]; then
        if ! vm_start "$Virsh_uri" "$Ubuntu_VM_name" "$Ubuntu_IP" "$Ubuntu_SSH_port"; then
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

    # Prepare build directory
    echo "Prepare build directory..."
    $SSHP "cd \"$Ubuntu_working_dir\"
           if [ -e \"$Build_dir\" ] ; then
               rf -fr \"$Build_dir\"
           fi
           mkdir \"$Build_dir\""

    # Get the sources
    scp -qrP $Ubuntu_SSH_port prepare_source/{ZL/ZenLib,MIL/MediaInfoLib,MC/MediaConch} \
             "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir\\"

    # Build Snap
    echo "Make MC Snap Image..."

    $SSHP "cd \"$Ubuntu_working_dir/$Build_dir\"
           cp -rf MediaConch/Project/Snap/mediaconch/* .
           snapcraft cleanbuild
           snapcraft --target-arch i386 cleanbuild
           cp -rf MediaConch/Project/Snap/mediaconch-server/* .
           snapcraft cleanbuild
           snapcraft --target-arch i386 cleanbuild
           cp -rf MediaConch/Project/Snap/mediaconch-gui/* .
           snapcraft cleanbuild

           # Bug, snapcraft wrongly consider compiling in a 32 bit container on 64 bit system
           # as cross-compilation and refuses to build mediaconch-gui since qt5-desktop module
           # don't support cross-compile. So we have to do the job manually.

           lxc launch -e ubuntu:xenial/i386 xenial$Container_name
           lxc file push -r ZenLib xenial$Container_name/root
           lxc file push -r MediaInfoLib xenial$Container_name/root
           lxc file push -r MediaConch xenial$Container_name/root
           # Bug, lxc eat directory name first letter
           lxc exec xenial$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec xenial$Container_name -- mv enLib ZenLib
           lxc exec xenial$Container_name -- mv ediaConch MediaConch
           lxc exec xenial$Container_name -- cp -rf MediaConch/Project/Snap/mediaconch-gui/* .
           lxc exec xenial$Container_name -- apt-get update
           lxc exec xenial$Container_name -- apt-get install snapcraft -y
           lxc exec xenial$Container_name -- snapcraft
           lxc file pull xenial$Container_name/root/mediaconch-gui_${Version_new}_i386.snap .
           lxc delete -f xenial$Container_name"

    # Build AppImage
    echo "Make MC AppImage..."

    $SSHP "cd \"$Ubuntu_working_dir/$Build_dir\"
           lxc launch -e images:centos/6/amd64 centos64$Container_name
           lxc file push -r ZenLib centos64$Container_name/root
           lxc file push -r MediaInfoLib centos64$Container_name/root
           lxc file push -r MediaConch centos64$Container_name/root
           # Bug, lxc eat first directory name letter
           lxc exec centos64$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec centos64$Container_name -- mv enLib ZenLib
           lxc exec centos64$Container_name -- mv ediaConch MediaConch
           lxc exec centos64$Container_name -- cp -f MediaConch/Project/AppImage/Recipe.sh .
           lxc exec centos64$Container_name -- sh Recipe.sh
           lxc file pull -r centos64$Container_name/root/out/mediaconch-${Version_new}-x86_64.AppImage .
           lxc file pull -r centos64$Container_name/root/out/mediaconch-server-${Version_new}-x86_64.AppImage .
           lxc file pull -r centos64$Container_name/root/out/mediaconch-gui-${Version_new}-x86_64.AppImage .
           lxc delete -f centos64$Container_name

           lxc launch -e images:centos/6/i386 centos$Container_name
           lxc file push -r ZenLib centos$Container_name/root
           lxc file push -r MediaInfoLib centos$Container_name/root
           lxc file push -r MediaConch centos$Container_name/root
           # Bug, lxc eat first directory name letter
           lxc exec centos$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec centos$Container_name -- mv enLib ZenLib
           lxc exec centos$Container_name -- mv ediaConch MediaConch
           lxc exec centos$Container_name -- cp -f MediaConch/Project/AppImage/Recipe.sh .
           lxc exec centos$Container_name -- sh Recipe.sh
           lxc file pull -r centos$Container_name/root/out/mediaconch-${Version_new}-i686.AppImage .
           lxc file pull -r centos$Container_name/root/out/mediaconch-server-${Version_new}-i686.AppImage .
           lxc file pull -r centos$Container_name/root/out/mediaconch-gui-${Version_new}-i686.AppImage .
           lxc delete -f centos$Container_name"

    # Retrieve files
    echo "Retreive files"

    File="mediaconch_${Version_new}_amd64.snap"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-server_${Version_new}_amd64.snap"
    test -e "$MCD_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-gui_${Version_new}_amd64.snap"
    test -e "$MCG_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch_${Version_new}_i386.snap"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-server_${Version_new}_i386.snap"
    test -e "$MCD_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-gui_${Version_new}_i386.snap"
    test -e "$MCG_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-${Version_new}-x86_64.AppImage"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-server-${Version_new}-x86_64.AppImage"
    test -e "$MCD_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-gui-${Version_new}-x86_64.AppImage"
    test -e "$MCG_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"


    File="mediaconch-${Version_new}-i686.AppImage"
    test -e "$MCC_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-server-${Version_new}-i686.AppImage"
    test -e "$MCD_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCD_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediaconch-gui-${Version_new}-i686.AppImage"
    test -e "$MCG_dir/$File" && rm "$MCC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MCG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    # Cleaning
    echo "Cleaning..."

    $SSHP "cd \"$Ubuntu_working_dir\" && rm -fr \"$Build_dir\""

    # Stop the VM
    if [ -n "$Ubuntu_VM_name" ] && [ -n "$Virsh_uri" ]; then
        vm_stop "$Virsh_URI" "$Ubuntu_VM_name"
    fi

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi

    return 0
}


function _obs () {

    local OBS_package="$OBS_project/MediaConch"

    cd "$MC_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/mediaconch_${Version_new}.tar.xz $OBS_package
    cp prepare_source/archives/mediaconch_${Version_new}.tar.gz $OBS_package

    # Create Debian packages and dsc
    deb_obs "$MC_tmp"/$OBS_package mediaconch_${Version_new}.tar.xz

    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.spec $OBS_package
    cp prepare_source/MC/MediaConch/Project/GNU/PKGBUILD $OBS_package

    update_PKGBUILD "$MC_tmp"/$OBS_package mediaconch_${Version_new}.tar.xz PKGBUILD

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
    echo python Handle_OBS_results.py $* $OBS_project MediaConch $Version_new "$MCC_dir" "$MCD_dir" "$MCG_dir"
    echo

    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $* $OBS_project MediaConch $Version_new "$MCC_dir" "$MCD_dir" "$MCG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

    if ! b.opt.has_flag? --skip-images && [ ! $(b.opt.get_opt --rebuild) ] ; then
        _linux_images
    fi
}

function btask.BuildRelease.run () {

    local UV_flags MSG PJ
    local MCC_dir="$Working_dir"/binary/mediaconch/$Sub_dir
    local MCD_dir="$Working_dir"/binary/mediaconch-server/$Sub_dir
    local MCG_dir="$Working_dir"/binary/mediaconch-gui/$Sub_dir
    local MCS_dir="$Working_dir"/source/mediaconch/$Sub_dir
    local MC_tmp="$Working_dir"/tmp/mediaconch/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MC_tmp"

    mkdir -p "$MCC_dir"
    # $MCS_dir is already taken for MediaConch Source
    mkdir -p "$MCD_dir"
    mkdir -p "$MCG_dir"

    if [ $(b.opt.get_opt --rebuild) ] ; then
        _linux --filter $(b.opt.get_opt --rebuild)
        exit 0
    fi

    mkdir -p "$MCS_dir"
    mkdir -p "$MC_tmp"

    cd "$MC_tmp"
    mkdir upgrade_version
    mkdir prepare_source
    mkdir repos

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$MC_tmp"/upgrade_version/MediaConch_SourceCode
    else
        pushd "$MC_tmp"/upgrade_version
        git clone "$Repo"
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MC_tmp"/upgrade_version/MediaConch_SourceCode
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $MC_tmp/upgrade_version/MediaConch_SourceCode/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    # Get MIL version to depend on
    UV_flags=""
    if [ $(b.opt.get_opt --new) ] && ! b.opt.has_flag? --keep-mil-dep; then
        pushd "$MC_tmp"/repos
        git clone "https://github.com/MediaArea/MediaInfoLib.git"
        popd

        if [ $(b.opt.get_opt --mil-gs) ]; then
            pushd  "$MC_tmp"/repos/MediaInfoLib
            git checkout "$(sanitize_arg $(b.opt.get_opt --mil-gs))"
            popd
        fi

        UV_flags="-mv $(cat $MC_tmp/repos/MediaInfoLib/Project/version.txt)"
    fi

    if [ $(b.opt.get_opt --zl-version) ]; then
         UV_flags="${UV_flags} -zv $(sanitize_arg $(b.opt.get_opt --zl-version))"
    fi

    if b.opt.has_flag? --commit ; then
        UV_flags="${UV_flags} -c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -n $Version_new $UV_flags -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    find "$MCS_dir" -mindepth 1 -delete
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mc -v $Version_new -wp "$MC_tmp"/prepare_source -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode $PS_target -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Linux] Problem building MC" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}.* "$MCS_dir"
    fi

    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG= PJ=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo "echo -e \"$MSG\" | mailx -s \"[BR Mac] Problem building MC\" ${Email_CC/$Email_CC/-c $Email_CC} ${PJ} $Email_to"
        fi

        mv "$MC_tmp"/prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* "$MCC_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_Server_${Version_new}_GNU_FromSource.* "$MCD_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* "$MCG_dir"
    fi

    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building MC" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z "$MCS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MC_tmp"
    fi
}
