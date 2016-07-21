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
                    MediaInfo/Project/Mac/Prepare_for_Xcode.sh"
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
    until [ `ls -l "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq $NbTry ]; do
        _mac_cli
        # Return 1 if MI-cli is compiled for i386 and x86_64,
        # 0 otherwise
        MultiArch=`ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP "file $Mac_working_dir/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg
    until [ `ls -l "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq $NbTry ]; do
        _mac_gui
        Try=$(($Try + 1))
    done

    # Send a mail if a build fail

    # If the CLI dmg is less than 5 Mo
    if [ `ls -l "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 5000000 ] || [ $MultiArch -eq 0 ]; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            if ! [ -z "$Email_CC" ]; then
                echo "The CLI dmg is less than 5 Mo. The log is http://url/$Log/mac-cli.log" | mailx -s "[BR mac] Problem building MI-cli" -a $Log/mac-cli.log.xz -c "$Email_CC" $Email_to
            else
                echo "The CLI dmg is less than 5 Mo. The log is http://url/$Log/mac-cli.log" | mailx -s "[BR mac] Problem building MI-cli" -a $Log/mac-cli.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The CLI dmg is less than 5 Mo" | mailx -s "[BR mac] Problem building MI-cli" -c "$Email_CC" $Email_to
            else
                echo "The CLI dmg is less than 5 Mo" | mailx -s "[BR mac] Problem building MI-cli" $Email_to
            fi
        fi
    fi

    # If the GUI dmg is less than 4 Mo
    if [ `ls -l "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 4000000 ] ; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-gui.log
            if ! [ -z "$Email_CC" ]; then
                echo "The GUI dmg is less than 4 Mo. The log is http://url/$Log/mac-gui.log" | mailx -s "[BR mac] Problem building MI-gui" -a $Log/mac-gui.log.xz -c "$Email_CC" $Email_to
            else
                echo "The GUI dmg is less than 4 Mo. The log is http://url/$Log/mac-gui.log" | mailx -s "[BR mac] Problem building MI-gui" -a $Log/mac-gui.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The GUI dmg is less than 4 Mo" | mailx -s "[BR mac] Problem building MI-gui" -c "$Email_CC" $Email_to
            else
                echo "The GUI dmg is less than 4 Mo" | mailx -s "[BR mac] Problem building MI-gui" $Email_to
            fi
        fi
    fi

}

function _windows () {

    local Try=5 VM_started=0 SSHP Build_dir MSG DLPath File

    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    Build_dir="build_$RANDOM"

    cd "$MI_tmp"

    # Windows binaries are kept apart from the others
    mkdir -p "win_binary/libmediainfo0/$Version_new"
    mkdir -p "win_binary/mediainfo/$Version_new"
    mkdir -p "win_binary/mediainfo-gui/$Version_new"
    mkdir -p "win_donors/$Version_new"

    # Start the VM if needed
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ] ; then
        if ! vm_is_running "$Virsh_uri" "$Win_VM_name" ; then
            echo "Starting Windows VM..."
            vm_start "$Virsh_uri" "$Win_VM_name" || (echo "ERROR: unable to start VM" >&2 && return 1)

            # Allow time for VM startup
            for i in $(seq $Try) ; do
                sleep 30 ; $SSHP "exit" && (sleep 3 ; break)
            done

            VM_started="1"
        fi
    fi

    # Test connection
    $SSHP "exit" || (echo "ERROR: unable to connect to host" >&2 && return 1)
    sleep 3

    # Prepare build directory
    echo "Prepare build directory..."
    $SSHP "Set-Location \"$Win_working_dir\"; if(Test-Path \"$Build_dir\") { Remove-Item -Force -Recurse \"$Build_dir\" }"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\"; New-Item -Type \"directory\" \"$Build_dir\""
    sleep 3

    # Get the tools
    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"; if(Test-Path \"$Win_working_dir\\MediaArea-Utils\\.git\") {git clone --quiet \"$Win_working_dir\\MediaArea-Utils\"} else { git clone --quiet \"https://github.com/MediaArea/MediaArea-Utils.git\" }"
    sleep 3

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\"; if(Test-Path \"$Win_working_dir\\MediaArea-Utils-Binaries\\.git\") {git clone --quiet \"$Win_working_dir\\MediaArea-Utils-Binaries\"} else { git clone --quiet \"https://github.com/MediaArea/MediaArea-Utils-Binaries.git\" }"
    sleep 3

    # Get the sources
    scp -P $Win_SSH_port "prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\" || (echo "ERROR: unable to get the sources" >&2 && return 1)
    sleep 3

    # Build
    echo "Compile MI for Windows..."

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\\MediaArea-Utils\\build_release\"; cmd /c \"BuildRelease.bat MI /archive 2>&1\""
    sleep 3

    # Retrieve files
    echo "Retreive files..."
    DLPath="MediaArea-Utils\\build_release\\Release\\download\\binary"

    File="MediaInfo_DLL_${Version_new}_Windows_i386_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\${Version_new%.????????}\\MediaInfo_DLL_${Version_new%.????????}_Windows_i386_WithoutInstaller.7z" \
                         "win_binary/libmediainfo0/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_x64_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\${Version_new%.????????}\\MediaInfo_DLL_${Version_new%.????????}_Windows_x64_WithoutInstaller.7z" \
                         "win_binary/libmediainfo0/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_i386.exe"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\${Version_new%.????????}\\MediaInfo_DLL_${Version_new%.????????}_Windows_i386.exe" \
                         "win_binary/libmediainfo0/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_DLL_${Version_new}_Windows_x64.exe"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\libmediainfo0\\${Version_new%.????????}\\MediaInfo_DLL_${Version_new%.????????}_Windows_x64.exe" \
                         "win_binary/libmediainfo0/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_CLI_${Version_new}_Windows_i386.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo\\${Version_new%.????????}\\MediaInfo_CLI_${Version_new%.????????}_Windows_i386.zip" \
                         "win_binary/mediainfo/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_CLI_${Version_new}_Windows_x64.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo\\${Version_new%.????????}\\MediaInfo_CLI_${Version_new%.????????}_Windows_x64.zip" \
                         "win_binary/mediainfo/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows_i386_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\${Version_new%.????????}\\MediaInfo_GUI_${Version_new%.????????}_Windows_i386_WithoutInstaller.7z" \
                         "win_binary/mediainfo-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows_x64_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\${Version_new%.????????}\\MediaInfo_GUI_${Version_new%.????????}_Windows_x64_WithoutInstaller.7z" \
                         "win_binary/mediainfo-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaInfo_GUI_${Version_new}_Windows.exe"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediainfo-gui\\${Version_new%.????????}\\MediaInfo_GUI_${Version_new%.????????}_Windows.exe" \
                         "win_binary/mediainfo-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    # Download thank version only in release mode
    if [ -n "$Win_donors_dir" ] && [ "${Version_new%.????????}" == "${Version_new}" ] ; then
        File="MediaInfo_GUI_${Version_new}_Windows.exe"
        scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\..\\..\\..\\ThankYou\\${Version_new%.????????}\\MediaInfo_GUI_${Version_new%.????????}_Windows.exe" \
                             "win_donors/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3
    fi

    # Check errors
    if [ -n "$MSG" ]; then
        if ! [ -z "$Email_CC" ]; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building MI" -c "$Email_CC" $Email_to
        else
            echo -e "$MSG" | mailx -s "[BR WIndows] Problem building MI" $Email_to
        fi
        echo -e $MSG 1>&2
    fi

    # Copy files to the final destination
    if [ -e "win_donors/$Sub_dir/MediaInfo_GUI_${Version_new}_Windows.exe" ] ; then
        scp -r "win_donors/." "$Win_donors_dir"
    fi

    scp -r "win_binary/." "$Win_binary_dir"

    # Cleaning
    echo "Cleaning..."
    rm -rf "win_donors"
    rm -rf "win_binary"

    $SSHP "Set-Location \"$Win_working_dir\"; Remove-Item -Force -Recurse \"$Build_dir\""

    # Stop the VM
    if [ "$VM_started" == "1" ] ; then
        vm_stop "$Virsh_URI" "$Win_VM_name"
    fi
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

    cp prepare_source/archives/mediainfo_${Version_new}.tar.xz $OBS_package/mediainfo_${Version_new}.orig.tar.xz
    cp prepare_source/archives/mediainfo_${Version_new}.tar.gz $OBS_package

    cd $OBS_package
    tar xf mediainfo_${Version_new}.orig.tar.xz
    mv MediaInfo/debian .
    rm -fr MediaInfo
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f mediainfo_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/MI/MediaInfo/Project/GNU/mediainfo.spec $OBS_package
    cp prepare_source/MI/MediaInfo/Project/GNU/mediainfo.dsc $OBS_package/mediainfo_${Version_new}-1.dsc
    cp prepare_source/MI/MediaInfo/Project/GNU/PKGBUILD $OBS_package

    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}.orig.tar.xz mediainfo_${Version_new}-1.dsc
    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}-1.debian.tar.xz mediainfo_${Version_new}-1.dsc

    update_PKGBUILD "$MI_tmp"/$OBS_package mediainfo_${Version_new}.orig.tar.xz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb () {

    # This function build the source on OBS for a specific debian
    # version.

    local Deb_version="$1"
    local OBS_package="$OBS_project/MediaInfo_$Deb_version"

    cd "$MI_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/mediainfo_${Version_new}.tar.xz $OBS_package
    cd $OBS_package
    tar xf mediainfo_${Version_new}.tar.xz
    rm -fr mediainfo_${Version_new}.tar.xz
    rm -fr MediaInfo/debian ; mv MediaInfo/Project/OBS/${Deb_version}.debian MediaInfo/debian
    cp -r MediaInfo/debian .
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f mediainfo_${Version_new}.orig.tar.xz MediaInfo)
    rm -fr MediaInfo
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f mediainfo_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/MI/MediaInfo/Project/OBS/${Deb_version}.dsc $OBS_package/mediainfo_${Version_new}-1.dsc

    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}.orig.tar.xz mediainfo_${Version_new}-1.dsc
    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}-1.debian.tar.xz mediainfo_${Version_new}-1.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb6 () {

    # This function build the source on OBS for Debian 6.

    local OBS_package="$OBS_project/MediaInfo_deb6"

    cd "$MI_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/mediainfo_${Version_new}.tar.gz $OBS_package
    cd $OBS_package
    tar xf mediainfo_${Version_new}.tar.gz
    rm -fr MediaInfo/debian ; mv MediaInfo/Project/OBS/deb6.debian MediaInfo/debian
    (GZIP=-9 tar -cz --owner=root --group=root -f mediainfo_${Version_new}.tar.gz MediaInfo)
    rm -fr MediaInfo
    cd ../..

    cp prepare_source/MI/MediaInfo/Project/OBS/deb6.dsc $OBS_package/mediainfo_${Version_new}.dsc

    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}.tar.gz mediainfo_${Version_new}.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_mga () {

    # This function build the source on OBS for a specific mageia
    # version.

    local Mga_version="$1"
    local OBS_package="$OBS_project/MediaInfo_$Mga_version"

    cd "$MI_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/mediainfo_${Version_new}.tar.gz $OBS_package
    cp prepare_source/MI/MediaInfo/Project/OBS/mga5.spec $OBS_package/mediainfo.spec

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    _obs
    _obs_deb deb9
    _obs_deb deb7
    _obs_deb6
    _obs_mga mga5
    echo
    echo Launch in background the python script which check
    echo the build results and download the packages...
    echo
    echo The command line is:
    echo python Handle_OBS_results.py $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir"
    echo

    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log & 
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb9 $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_deb9.log 2>"$Log"/obs_deb9-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb7 $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_deb7.log 2>"$Log"/obs_deb7-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb6 $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_deb6.log 2>"$Log"/obs_deb6-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_mga5 $Version_new "$MIC_dir" "$MIG_dir" >"$Log"/obs_mga5.log 2>"$Log"/obs_mga5-error.log &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $Working_dir/`date +%Y%m%d`; then
    #    mv $Working_dir/`date +%Y%m%d` $Working_dir/`date +%Y%m%d`-1
    #    Working_dir=$Working_dir/`date +%Y%m%d`-2
    #    mkdir -p $Working_dir
    # + handle a third run, etc
        
    local MIC_dir="$Working_dir"/binary/mediainfo/$Sub_dir
    local MIG_dir="$Working_dir"/binary/mediainfo-gui/$Sub_dir
    local MIS_dir="$Working_dir"/source/mediainfo/$Sub_dir
    local MI_tmp="$Working_dir"/tmp/mediainfo/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MIC_dir"
    rm -fr "$MIG_dir"
    rm -fr "$MIS_dir"
    rm -fr "$MI_tmp"

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
        cp -r "$Source_dir" "$MI_tmp"/upgrade_version/MediaInfo
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -sp "$MI_tmp"/upgrade_version/MediaInfo
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -wp "$MI_tmp"/upgrade_version
    fi

    local MIL_gs=""
    if [ $(b.opt.get_opt --mil-gs) ]; then
        MIL_gs="-gs $(sanitize_arg $(b.opt.get_opt --mil-gs))"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -wp "$MI_tmp"/upgrade_version $MIL_gs

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mi -v $Version_new -wp "$MI_tmp"/prepare_source -sp "$MI_tmp"/upgrade_version/MediaInfo $PS_target -nc

    if [ "$Target" = "mac" ]; then
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z "$MIS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}.* "$MIS_dir"
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            # Linux first, in order that OBS build while the mac and windows tasks are # executed
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _linux
            _mac
            _windows
        fi
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z "$MIS_dir"
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}.* "$MIS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MI_tmp"
    fi

}
