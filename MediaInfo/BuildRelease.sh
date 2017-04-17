# MediaInfo/Release/BuildRelease.sh
# Build a release of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {

    cd "$MI_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaInfo_CLI*"

    echo
    echo "Compile MI CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_CLI_GNU_FromSource ;
            MediaInfo/Project/Mac/BR_extension_CLI.sh ;
            $Key_chain ;
            cd MediaInfo/Project/Mac ;
            ./Make_MI_dmg.sh cli $Version_new"

    test -e "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg && rm "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_CLI_${Version_new}_Mac.dmg "$MIC_dir"

}

function _mac_gui () {

    local Dylib_OK

    cd "$MI_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaInfo_GUI*"

    echo
    echo "Compile MI GUI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_GUI_GNU_FromSource ;
            mkdir -p Shared/Source
            cp -r ~/Documents/almin/WxWidgets Shared/Source
            MediaInfo/Project/Mac/BR_extension_GUI.sh ;
            $Key_chain ;
            cd MediaInfo/Project/Mac ;
            ./Make_MI_dmg.sh gui $Version_new"

    test -e "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg && rm "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_GUI_${Version_new}_Mac.dmg "$MIG_dir"

    if ! b.opt.has_flag? --snapshot; then

        # Return 1 if the dylib is present, 0 otherwise
        Dylib_OK=`ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP "ls $Mac_working_dir/dylib_for_xcode/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz" |wc -l`

        if [ $Dylib_OK -eq 1 ]; then
            echo
            echo
            echo "Preparing for Xcode..."
            echo
            $SSHP "cd $Mac_working_dir/dylib_for_xcode ;
                    rm -fr MediaInfoLib ;
                    tar xf MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz ;
                    cd ../MediaInfo_GUI_GNU_FromSource ;
                    MediaInfo/Project/Mac/Prepare_for_Xcode.sh
                    sed -i '' \\
                        -e 's/^\([[:space:]]*\)CODE_SIGN_ENTITLEMENTS = MediaInfo.entitlements;\$/&\'\$'\n''\1CODE_SIGN_IDENTITY = \"Mac Developer\";/g' \\
                        MediaInfo/Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj
                    sed -i '' \\
                        -e 's/^\([[:space:]]*\)CODE_SIGN_ENTITLEMENTS = MediaInfo.entitlements;\$/&\'\$'\n''\1DEVELOPMENT_TEAM = \"$Dev_team\";/g' \\
                        MediaInfo/Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj
                    sed -i '' \\
                        -e 's/^\([[:space:]]*\)ORGANIZATIONNAME = MediaArea.net;\$/&\'\$'\n''\1TargetAttributes = { 8D1107260486CEB800E47090 = { DevelopmentTeam = $Dev_team; ProvisioningStyle = Automatic; }; };/g' \\
                        MediaInfo/Source/GUI/Cocoa/MediaInfo.xcodeproj/project.pbxproj


                    cd MediaInfo/Source/GUI/Cocoa/
                    $Key_chain
                    xcodebuild -scheme MediaInfo archive"
        else
            echo
            echo
            echo
            echo
            echo "WARNING! Can’t found the dylib in $Mac_working_dir/dylib_for_xcode!"
            echo "It’s probably because you have not run BR.sh for MIL"
            echo "before launching BR.sh for MI."
            echo
            echo
            echo
            echo
        fi

    fi

}

function _mac () {

    # This function test the success of the compilation by testing
    # size and multiarch. If fail, retry to compile up to 3 times.

    local SSHP NbTry Try MultiArch

    # SSH prefix
    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"
    NbTry=3

    cd "$MI_tmp"

    MultiArch=0
    Try=0
    touch "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg
    until [ 0`stat -c %s "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg 2>/dev/null` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq $NbTry ]; do
        _mac_cli
        # Return 1 if MI-cli is compiled for i386 and x86_64,
        # 0 otherwise
        MultiArch=`ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP "file $Mac_working_dir/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg
    until [ 0`stat -c %s "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg 2>/dev/null` -gt 4000000 ] || [ $Try -eq $NbTry ]; do
        _mac_gui
        Try=$(($Try + 1))
    done

    # Send a mail on errors

    # Test mediainfo executable
	$SSHP "$Mac_working_dir/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo --version" &>/dev/null
    if [ $? -ne 0 ] ; then
        MSG="${MSG}Error $? when trying execute mediainfo.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            PJ="${PJ} -a $Log/mac-cli.log.xz"
        fi
    fi

    # If the CLI dmg is less than 5 Mo
    if [ 0`stat -c %s "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg 2>/dev/null` -lt 5000000 ]; then
        MSG="${MSG}The CLI dmg is less than 5 Mo.\n"
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            PJ="${PJ} -a $Log/mac-cli.log.xz"
        fi
    fi

    # If the GUI dmg is less than 4 Mo
    if [ 0`stat -c %s "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg 2>/dev/null` -lt 4000000 ]; then
        MSG="${MSG}The GUI dmg is less than 4 Mo.\n"
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

    cd "$MI_tmp"

    # Donors binaries are kept apart from the others
    mkdir -p "win_donors/$Sub_dir"

    # Start the VM if needed
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ]; then
        echo "Starting Windows VM..."
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
    scp -P $Win_SSH_port "prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    # Build
    echo "Compile MI for Windows..."

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\\MediaArea-Utils\\build_release\"; cmd /c \"BuildRelease.bat MI /archive 2>&1\""
    sleep 3

    # Test MediaInfo executables
    $SSHP "$Win_working_dir\\$Build_dir\\mediainfo_AllInclusive\\MediaInfo\\Project\\MSVC2015\\Win32\\Release\\MediaInfo.exe --version" &>/dev/null || \
           MSG="${MSG}Error $? when trying execute MediaInfo.exe (Win32).\n"

    $SSHP "$Win_working_dir\\$Build_dir\\mediainfo_AllInclusive\\MediaInfo\\Project\\MSVC2015\\x64\\Release\\MediaInfo.exe --version" &>/dev/null || \
           MSG="${MSG}Error $? when trying execute MediaInfo.exe (x64).\n"

    # Retrieve files
    echo "Retreive files..."
    DLPath="MediaArea-Utils\\build_release\\Release\\download\\binary"

    File="MediaInfo_DLL_${Version_new}_Windows_i386_WithoutInstaller.7z"
    test -e "$MIL_dir/$File" && rm "$MIL_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_DLL_$(cut -d. -f1-3 <<<$Version_new)_Windows_i386_WithoutInstaller.7z" \
                         "$MIL_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_x64_WithoutInstaller.7z"
    test -e "$MIL_dir/$File" && rm "$MIL_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_DLL_$(cut -d. -f1-3 <<<$Version_new)_Windows_x64_WithoutInstaller.7z" \
                         "$MIL_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_i386.exe"
    test -e "$MIL_dir/$File" && rm "$MIL_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_DLL_$(cut -d. -f1-3 <<<$Version_new)_Windows_i386.exe" \
                         "$MIL_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_x64.exe"
    test -e "$MIL_dir/$File" && rm "$MIL_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_DLL_$(cut -d. -f1-3 <<<$Version_new)_Windows_x64.exe" \
                         "$MIL_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_CLI_${Version_new}_Windows_i386.zip"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_CLI_$(cut -d. -f1-3 <<<$Version_new)_Windows_i386.zip" \
                         "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_CLI_${Version_new}_Windows_x64.zip"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_CLI_$(cut -d. -f1-3 <<<$Version_new)_Windows_x64.zip" \
                         "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows_i386_WithoutInstaller.7z"
    test -e "$MIG_dir/$File" && rm "$MIG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_GUI_$(cut -d. -f1-3 <<<$Version_new)_Windows_i386_WithoutInstaller.7z" \
                         "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows_x64_WithoutInstaller.7z"
    test -e "$MIG_dir/$File" && rm "$MIG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_GUI_$(cut -d. -f1-3 <<<$Version_new)_Windows_x64_WithoutInstaller.7z" \
                         "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows.exe"
    test -e "$MIG_dir/$File" && rm "$MIG_dir/$File"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_GUI_$(cut -d. -f1-3 <<<$Version_new)_Windows.exe" \
                         "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    # Download thank version only in release mode
    if [ -n "$Win_donors_dir" ] && [ "${Version_new%.????????}" == "${Version_new}" ] ; then
        File="MediaInfo_GUI_${Version_new}_Windows.exe"
        scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\..\\..\\..\\ThankYou\\$(cut -d. -f1-3 <<<$Version_new)\\MediaInfo_GUI_$(cut -d. -f1-3 <<<$Version_new)_Windows.exe" \
                             "win_donors/$Sub_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3
    fi

    # Copy files to the final destination
    if [ -e "win_donors/$Sub_dir/MediaInfo_GUI_${Version_new}_Windows.exe" ] ; then
        scp -r "win_donors/." "$Win_donors_dir"
    fi

    # Cleaning
    echo "Cleaning..."
    rm -rf "win_donors"

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
    Container_name=$RANDOM

    cd "$MI_tmp"

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
    scp -qrP $Ubuntu_SSH_port prepare_source/{ZL/ZenLib,MIL/MediaInfoLib,MI/MediaInfo} \
             "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir\\"


    # Build Snap
    echo "Make MI Snap Image..."

    $SSHP "cd \"$Ubuntu_working_dir/$Build_dir\"
           cp -rf MediaInfo/Project/Snap/mediainfo/* .
           snapcraft cleanbuild
           snapcraft --target-arch i386 cleanbuild
           cp -rf MediaInfo/Project/Snap/mediainfo-gui/* .
           snapcraft cleanbuild

           # Bug, snapcraft wrongly consider compiling in a 32 bit container on 64 bit system
           # as cross-compilation and refuses to build mediaconch-gui since gtk-desktop module
           # don't support cross-compile. So we have to do the job manually.

           lxc launch -e ubuntu:xenial/i386 xenial$Container_name
           lxc file push -r ZenLib xenial$Container_name/root
           lxc file push -r MediaInfoLib xenial$Container_name/root
           lxc file push -r MediaInfo xenial$Container_name/root
           # Bug, lxc eat directory name first letter
           lxc exec xenial$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec xenial$Container_name -- mv enLib ZenLib
           lxc exec xenial$Container_name -- mv ediaInfo MediaInfo
           lxc exec xenial$Container_name -- cp -rf MediaInfo/Project/Snap/mediainfo-gui/* .
           lxc exec xenial$Container_name -- apt-get update
           lxc exec xenial$Container_name -- apt-get install snapcraft -y
           lxc exec xenial$Container_name -- snapcraft
           lxc file pull xenial$Container_name/root/mediainfo-gui_${Version_new}_i386.snap .
           lxc delete -f xenial$Container_name"

    # Build AppImage
    echo "Make MI AppImage..."

    $SSHP "cd \"$Ubuntu_working_dir/$Build_dir\"
           lxc launch -e -c 'security.privileged=true' images:centos/6/amd64 centos64$Container_name
           lxc file push -r ZenLib centos64$Container_name/root
           lxc file push -r MediaInfoLib centos64$Container_name/root
           lxc file push -r MediaInfo centos64$Container_name/root
           # Bug, lxc eat first directory name letter
           lxc exec centos64$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec centos64$Container_name -- mv enLib ZenLib
           lxc exec centos64$Container_name -- mv ediaInfo MediaInfo
           lxc exec centos64$Container_name -- cp -f MediaInfo/Project/AppImage/Recipe.sh .
           lxc exec centos64$Container_name -- sh Recipe.sh
           lxc file pull -r centos64$Container_name/root/out/mediainfo-${Version_new}-x86_64.AppImage .
           lxc file pull -r centos64$Container_name/root/out/mediainfo-gui-${Version_new}-x86_64.AppImage .
           lxc delete -f centos64$Container_name

           lxc launch -e -c 'security.privileged=true' images:centos/6/i386 centos$Container_name
           lxc file push -r ZenLib centos$Container_name/root
           lxc file push -r MediaInfoLib centos$Container_name/root
           lxc file push -r MediaInfo centos$Container_name/root
           # Bug, lxc eat first directory name letter
           lxc exec centos$Container_name -- mv ediaInfoLib MediaInfoLib
           lxc exec centos$Container_name -- mv enLib ZenLib
           lxc exec centos$Container_name -- mv ediaInfo MediaInfo
           lxc exec centos$Container_name -- cp -f MediaInfo/Project/AppImage/Recipe.sh .
           lxc exec centos$Container_name -- sh Recipe.sh
           lxc file pull -r centos$Container_name/root/out/mediainfo-${Version_new}-i686.AppImage .
           lxc file pull -r centos$Container_name/root/out/mediainfo-gui-${Version_new}-i686.AppImage .
           lxc delete -f centos$Container_name"

    # Retrieve files
    echo "Retreive files"

    File="mediainfo_${Version_new}_amd64.snap"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo-gui_${Version_new}_amd64.snap"
    test -e "$MIG_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo_${Version_new}_i386.snap"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo-gui_${Version_new}_i386.snap"
    test -e "$MIG_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo-${Version_new}-x86_64.AppImage"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo-gui-${Version_new}-x86_64.AppImage"
    test -e "$MIG_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"


    File="mediainfo-${Version_new}-i686.AppImage"
    test -e "$MIC_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIC_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

    File="mediainfo-gui-${Version_new}-i686.AppImage"
    test -e "$MIG_dir/$File" && rm "$MIC_dir/$File"
    scp -P $Ubuntu_SSH_port "$Ubuntu_SSH_user@$Ubuntu_IP:$Ubuntu_working_dir/$Build_dir/$File" \
           "$MIG_dir/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"

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

    local OBS_package="$OBS_project/MediaInfo"

    cd "$MI_tmp"

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

    if ! b.opt.has_flag? --only-images ; then
        _obs

        if ! b.opt.has_flag? --jenkins ; then
            echo
            echo Launch in background the python script which check
            echo the build results and download the packages...
            echo
            echo The command line is:
            echo python Handle_OBS_results.py $Filter $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir"
            echo

            cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
            python Handle_OBS_results.py $Filter $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
        else
            echo "#!/bin/bash" > "$WORKSPACE/STAGE"
            echo "python Handle_OBS_results.py $Filter $OBS_project MediaInfo $Version_new \"$MIC_dir\" \"$MIG_dir\"" >> "$WORKSPACE/STAGE"
            chmod +x "$WORKSPACE/STAGE"
        fi
    fi

    if ! b.opt.has_flag? --skip-images && ! b.opt.get_opt --filter ; then
        _linux_images
    fi
}

function btask.BuildRelease.run () {

    local MIL_gs UV_flags MSG PJ
    local MIL_dir="$Working_dir"/binary/libmediainfo0/$Sub_dir
    local MIC_dir="$Working_dir"/binary/mediainfo/$Sub_dir
    local MIG_dir="$Working_dir"/binary/mediainfo-gui/$Sub_dir
    local MIS_dir="$Working_dir"/source/mediainfo/$Sub_dir
    local MI_tmp="$Working_dir"/tmp/mediainfo/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MI_tmp"

    mkdir -p "$MIL_dir"
    mkdir -p "$MIC_dir"
    mkdir -p "$MIG_dir"

    mkdir -p "$MIS_dir"
    mkdir -p "$MI_tmp"

    cd "$MI_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$MI_tmp"/upgrade_version/MediaInfo
    else
        pushd "$MI_tmp"/upgrade_version
        git clone "$Repo" MediaInfo
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MI_tmp"/upgrade_version/MediaInfo
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $MI_tmp/upgrade_version/MediaInfo/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -n $Version_new $MIL_gs -wp "$MI_tmp"/upgrade_version

    UV_flags=""
    if [ $(b.opt.get_opt --new) ] && ! b.opt.has_flag? --keep-mil-dep; then
        UV_flags="-mv $(cat $MI_tmp/upgrade_version/MediaInfoLib/Project/version.txt)"
    fi

    if [ $(b.opt.get_opt --zl-version) ]; then
         UV_flags="${UV_flags} -zv $(sanitize_arg $(b.opt.get_opt --zl-version))"
    fi

    if b.opt.has_flag? --commit ; then
        UV_flags="${UV_flags} -c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -n $Version_new $UV_flags -sp "$MI_tmp"/upgrade_version/MediaInfo

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$MIS_dir" -name 'mediainfo_*.tar.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        find "$MIC_dir" "$MIG_dir" -name 'MediaInfo_*_GNU_FromSource.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        find "$MIS_dir" -name 'mediainfo_*_AllInclusive.7z' -mindepth 1 -delete
    fi

    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mi -v $Version_new -wp "$MI_tmp"/prepare_source -sp "$MI_tmp"/upgrade_version/MediaInfo $PS_target -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Linux] Problem building MI" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}.* "$MIS_dir"
    fi

    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG= PJ=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo "echo -e \"$MSG\" | mailx -s \"[BR Mac] Problem building MI\" ${Email_CC/$Email_CC/-c $Email_CC} ${PJ} $Email_to"
        fi

        mv "$MI_tmp"/prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"
    fi

    if [ "$Target" = "windows" ] || [ "$Target" = "all" ]; then
        MSG=
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building MI" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z "$MIS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MI_tmp"
    fi
}
