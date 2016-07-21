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
    until [ `ls -l "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 2000000 ] || [ $Try -eq $NbTry ]; do
        _mac_cli
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg
    until [ `ls -l "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 3000000 ] || [ $Try -eq $NbTry ]; do
        _mac_server
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg
    until [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 10000000 ] || [ $Try -eq $NbTry ]; do
        _mac_gui
        Try=$(($Try + 1))
    done

    # Send a mail if a build fail

    # If the CLI dmg is less than 3 Mo
    if [ `ls -l "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 3000000 ]; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-cli.log
            if ! [ -z "$Email_CC" ]; then
                echo "The CLI dmg is less than 3 Mo. The log is http://url/$Log/mac-cli.log" | mailx -s "[BR mac] Problem building MC-cli" -a $Log/mac-cli.log.xz -c "$Email_CC" $Email_to
            else
                echo "The CLI dmg is less than 3 Mo. The log is http://url/$Log/mac-cli.log" | mailx -s "[BR mac] Problem building MC-cli" -a $Log/mac-cli.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The CLI dmg is less than 3 Mo" | mailx -s "[BR mac] Problem building MC-cli" -c "$Email_CC" $Email_to
            else
                echo "The CLI dmg is less than 3 Mo" | mailx -s "[BR mac] Problem building MC-cli" $Email_to
            fi
        fi
    fi

    # If the server dmg is less than 3 Mo
    if [ `ls -l "$MCD_dir"/MediaConch_Server_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 3000000 ]; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-server.log
            if ! [ -z "$Email_CC" ]; then
                echo "The server dmg is less than 3 Mo. The log is http://url/$Log/mac-server.log" | mailx -s "[BR mac] Problem building MC-server" -a $Log/mac-server.log.xz -c "$Email_CC" $Email_to
            else
                echo "The server dmg is less than 3 Mo. The log is http://url/$Log/mac-server.log" | mailx -s "[BR mac] Problem building MC-server" -a $Log/mac-server.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The server dmg is less than 3 Mo" | mailx -s "[BR mac] Problem building MC-server" -c "$Email_CC" $Email_to
            else
                echo "The server dmg is less than 3 Mo" | mailx -s "[BR mac] Problem building MC-server" $Email_to
            fi
        fi
    fi

    # If the GUI dmg is less than 20 Mo
    if [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 20000000 ]; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac-gui.log
            if ! [ -z "$Email_CC" ]; then
                echo "The GUI dmg is less than 20 Mo. The log is http://url/$Log/mac-gui.log" | mailx -s "[BR mac] Problem building MC-gui" -a $Log/mac-gui.log.xz -c "$Email_CC" $Email_to
            else
                echo "The GUI dmg is less than 20 Mo. The log is http://url/$Log/mac-gui.log" | mailx -s "[BR mac] Problem building MC-gui" -a $Log/mac-gui.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The GUI dmg is less than 20 Mo" | mailx -s "[BR mac] Problem building MC-gui" -c "$Email_CC" $Email_to
            else
                echo "The GUI dmg is less than 20 Mo" | mailx -s "[BR mac] Problem building MC-gui" $Email_to
            fi
        fi
    fi

}

function _windows () {

    local Try=5 VM_started=0 SSHP Build_dir MSG DLPath File

    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    Build_dir="build_$RANDOM"

    cd "$MC_tmp"

    # Windows binaries are kept apart from the others
    mkdir -p "win_binary/mediaconch/$Version_new"
    mkdir -p "win_binary/mediaconch-gui/$Version_new"
    mkdir -p "win_binary/mediaconch-server/$Version_new"

    # Start the VM if needed
    if [ -n "$Win_VM_name" ] && [ -n "$Virsh_uri" ] ; then
        if ! vm_is_running "$Virsh_uri" "$Win_VM_name" ; then
            echo "Starting Windows VM..."
            vm_start "$Virsh_uri" "$Win_VM_name" || (echo "ERROR: unable to start VM" >&2 && return 1)

            # Allow time for VM startup
            for i in $(seq $Try) ; do
                sleep 30
                $SSHP "exit" && (sleep 3 ; break)
            done
            VM_started="1"
        fi
    fi

    # Test connection
    $SSHP "exit" || (echo "ERROR: unable to connect to host" >&2 && return 1)

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
    scp -P $Win_SSH_port "prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z" "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\"
    sleep 3

    # Build
    echo "Compile MC for Windows..."

    $SSHP "Set-Location \"$Win_working_dir\\$Build_dir\\MediaArea-Utils\\build_release\"; cmd /c \"BuildRelease.bat MC /archive 2>&1\""
    sleep 3

    # Retrieve files
    echo "Retreive files"
    DLPath="MediaArea-Utils\\build_release\\Release\\download\\binary"

    File="MediaConch_CLI_${Version_new}_Windows_i386.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch\\${Version_new%.????????}\\MediaConch_CLI_${Version_new%.????????}_Windows_i386.zip" \
                         "win_binary/mediaconch/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_CLI_${Version_new}_Windows_x64.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch\\${Version_new%.????????}\\MediaConch_CLI_${Version_new%.????????}_Windows_x64.zip" \
                         "win_binary/mediaconch/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows_i386_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows_i386_WithoutInstaller.7z" \
                         "win_binary/mediaconch-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows_x64_WithoutInstaller.7z"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows_x64_WithoutInstaller.7z" \
                         "win_binary/mediaconch-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_GUI_${Version_new}_Windows.exe"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-gui\\${Version_new%.????????}\\MediaConch_GUI_${Version_new%.????????}_Windows.exe" \
                         "win_binary/mediaconch-gui/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_Server_${Version_new}_Windows_i386.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-server\\${Version_new%.????????}\\MediaConch_Server_${Version_new%.????????}_Windows_i386.zip" \
                         "win_binary/mediaconch-server/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    File="MediaConch_Server_${Version_new}_Windows_x64.zip"
    scp -P $Win_SSH_port "$Win_SSH_user@$Win_IP:$Win_working_dir\\$Build_dir\\$DLPath\\mediaconch-server\\${Version_new%.????????}\\MediaConch_Server_${Version_new%.????????}_Windows_x64.zip" \
                         "win_binary/mediaconch-server/$Version_new/$File" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n" ; sleep 3

    # Check errors
    if [ -n "$MSG" ]; then
        if ! [ -z "$Email_CC" ]; then
            echo -e "$MSG" | mailx -s "[BR Windows] Problem building MC" -c "$Email_CC" $Email_to
        else
            echo -e "$MSG" | mailx -s "[BR WIndows] Problem building MC" $Email_to
        fi
        echo -e $MSG 1>&2
    fi

    # Copy files to the final destination
    scp -r "win_binary/." "$Win_binary_dir"

    # Cleaning
    echo "Cleaning..."
    rm -r "win_binary"

    $SSHP "Set-Location \"$Win_working_dir\"; Remove-Item -Force -Recurse \"$Build_dir\""

    # Stop the VM
    if [ "$VM_started" == "1" ] ; then
        vm_stop "$Virsh_URI" "$Win_VM_name"
    fi
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
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.spec $OBS_package
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.dsc $OBS_package/mediaconch_${Version_new}.dsc
    cp prepare_source/MC/MediaConch/Project/GNU/PKGBUILD $OBS_package

    update_DSC "$MC_tmp"/$OBS_package mediaconch_${Version_new}.tar.xz mediaconch_${Version_new}.dsc

    update_PKGBUILD "$MC_tmp"/$OBS_package mediaconch_${Version_new}.tar.xz PKGBUILD

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
    echo python Handle_OBS_results.py $OBS_project MediaConch $Version_new "$MCC_dir" "$MCD_dir" "$MCG_dir"
    echo

    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $OBS_project MediaConch $Version_new "$MCC_dir" "$MCD_dir" "$MCG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $Working_dir/`date +%Y%m%d`; then
    #    mv $Working_dir/`date +%Y%m%d` $Working_dir/`date +%Y%m%d`-1
    #    Working_dir=$Working_dir/`date +%Y%m%d`-2
    #    mkdir -p $Working_dir
    # + handle a third run, etc

    local Repo
    local MCC_dir="$Working_dir"/binary/mediaconch/$Sub_dir
    local MCD_dir="$Working_dir"/binary/mediaconch-server/$Sub_dir
    local MCG_dir="$Working_dir"/binary/mediaconch-gui/$Sub_dir
    local MCS_dir="$Working_dir"/source/mediaconch/$Sub_dir
    local MC_tmp="$Working_dir"/tmp/mediaconch/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MCC_dir"
    rm -fr "$MCD_dir"
    rm -fr "$MCG_dir"
    rm -fr "$MCS_dir"
    rm -fr "$MC_tmp"

    mkdir -p "$MCC_dir"
    # $MCS_dir is already taken for MediaConch Source
    mkdir -p "$MCD_dir"
    mkdir -p "$MCG_dir"
    mkdir -p "$MCS_dir"
    mkdir -p "$MC_tmp"

    cd "$MC_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    if [ $(b.opt.get_opt --repo) ]; then
        Repo="$(sanitize_arg $(b.opt.get_opt --repo))"
    else
        Repo="https://github.com/MediaArea/MediaConch_SourceCode"
    fi

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$MC_tmp"/upgrade_version/MediaConch_SourceCode
    else
        git -C "$MC_tmp"/upgrade_version clone "$Repo"
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $MC_tmp/upgrade_version/MediaConch_SourceCode/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -n $Version_new -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mc -v $Version_new -wp "$MC_tmp"/prepare_source -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode $PS_target -nc

    if [ "$Target" = "mac" ]; then
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi
        mv "$MC_tmp"/prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* "$MCC_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_Server_${Version_new}_GNU_FromSource.* "$MCD_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* "$MCG_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _windows
        fi
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z "$MCS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}.* "$MCS_dir"
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
            _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _linux
            _mac
            _windows
        fi
        mv "$MC_tmp"/prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* "$MCC_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_Server_${Version_new}_GNU_FromSource.* "$MCD_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* "$MCG_dir"
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z "$MCS_dir"
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}.* "$MCS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MC_tmp"
    fi

}
