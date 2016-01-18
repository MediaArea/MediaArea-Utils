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

            #cd MediaConch_CLI_${Version_new}_GNU_FromSource ;
    $SSHP "cd $Mac_working_dir ;
            tar xf MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_CLI_GNU_FromSource ;
            MediaConch/Project/Mac/BR_extension_CLI.sh ;
            $Key_chain ;
            cd MediaConch/Project/Mac ;
            ./Make_MC_dmg.sh cli $Version_new"

    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_CLI_${Version_new}_Mac.dmg "$MCC_dir"

}

function _mac_daemon () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaConch_Daemon*"

    echo
    echo "Compile MC daemon for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaConch_Daemon_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_Daemon_${Version_new}_GNU_FromSource.tar.xz

            #cd MediaConch_Daemon_${Version_new}_GNU_FromSource ;
    $SSHP "cd $Mac_working_dir ;
            tar xf MediaConch_Daemon_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_Daemon_GNU_FromSource ;
            MediaConch/Project/Mac/BR_extension_Daemon.sh ;
            $Key_chain ;
            cd MediaConch/Project/Mac ;
            ./Make_MC_dmg.sh daemon $Version_new"

    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaConch_Daemon_GNU_FromSource/MediaConch/Project/Mac/MediaConch_Daemon_${Version_new}_Mac.dmg "$MCC_dir"

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

            #cd MediaConch_GUI_${Version_new}_GNU_FromSource ;
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
        if b.opt.has_flag? --log; then
            _mac_cli >> "$Log"/mac-cli.log 2>&1
        else
            _mac_cli
        fi
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCC_dir"/MediaConch_Daemon_${Version_new}_Mac.dmg
    until [ `ls -l "$MCC_dir"/MediaConch_Daemon_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 3000000 ] || [ $Try -eq $NbTry ]; do
        if b.opt.has_flag? --log; then
            _mac_daemon >> "$Log"/mac-daemon.log 2>&1
        else
            _mac_daemon
        fi
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg
    until [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 10000000 ] || [ $Try -eq $NbTry ]; do
        if b.opt.has_flag? --log; then
            _mac_gui >> "$Log"/mac-gui.log 2>&1
        else
            _mac_gui
        fi
        Try=$(($Try + 1))
    done

    # Send a mail if the build fail
    if [ `ls -l "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 2000000 ]; then
        xz -9e $Log/mac-cli.log
        if ! [ -z "$MailCC" ]; then
            echo "The log is http://url/$Log/mac-cli.log.xz" | mailx -s "[BR mac] Problem building MC-cli" -a $Log/mac-cli.log.xz -c "$MailCC" $Mail
        else
            echo "The log is http://url/$Log/mac-cli.log.xz" | mailx -s "[BR mac] Problem building MC-cli" -a $Log/mac-cli.log.xz $Mail
        fi
    fi

    if [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 10000000 ]; then
        xz -9e $Log/mac-gui.log
        if ! [ -z "$MailCC" ]; then
            echo "The log is http://url/$Log/mac-gui.log.xz" | mailx -s "[BR mac] Problem building MC-gui" -a $Log/mac-gui.log.xz -c "$MailCC" $Mail
        else
            echo "The log is http://url/$Log/mac-gui.log.xz" | mailx -s "[BR mac] Problem building MC-gui" -a $Log/mac-gui.log.xz $Mail
        fi
    fi

}

function _windows () {

    local SSHP RWorking_dir

    # SSH prefix
    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    RWorking_dir="c:/Users/almin"

    cd "$MC_tmp"

    # Clean up
    $SSHP "c: & chdir $RWorking_dir & rmdir /S /Q build & md build"

    echo
    echo "Compile MC CLI for windows..."
    echo

    scp -P $Win_SSH_port prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z $Win_SSH_user@$Win_IP:$RWorking_dir/build/mediaconch_${Version_new}_AllInclusive.7z
            #xcopy /E /I /Q ..\\libxml2 mediaconch_${Version_new}_AllInclusive\\libxml2 & \
    $SSHP "c: & chdir $RWorking_dir/build & \
            c:/\"Program Files\"/7-Zip/7z x mediaconch_${Version_new}_AllInclusive.7z & \
            xcopy /E /I /Q ..\\libxml2 mediaconch_AllInclusive\\libxml2 & \

"
#            copy /Y ..\\MediaConch.vcxproj mediaconch_AllInclusive\\MediaConch\\Project\\MSVC2013\\CLI & \
#            copy /Y ..\\MediaInfoLib.vcxproj mediaconch_AllInclusive\\MediaInfoLib\\Project\\MSVC2013\\Library & \

#cd "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64"
#%comspec% /k ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"" amd64
#cd C:\Users\almin\build\mediaconch_AllInclusive\MediaConch\Project\MSVC2013\CLI
#msbuild MediaConch.vcxproj

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
    #cp prepare_source/MC/MediaConch_${Version_new}/Project/GNU/mediaconch.spec $OBS_package
    #cp prepare_source/MC/MediaConch_${Version_new}/Project/GNU/mediaconch.dsc $OBS_package/mediaconch_${Version_new}.dsc
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.spec $OBS_package
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.dsc $OBS_package/mediaconch_${Version_new}.dsc

    update_DSC "$MC_tmp"/$OBS_package mediaconch_${Version_new}.tar.xz mediaconch_${Version_new}.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    if b.opt.has_flag? --log; then
        _obs > "$Log"/linux.log 2>&1
    else
        _obs
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
    fi

    cd $(b.get bang.working_dir)
    python Handle_OBS_results.py $OBS_project MediaConch $Version_new "$MCC_dir" "$MCG_dir" > "$Log"/obs_main.log 2>&1 &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $Working_dir/`date +%Y%m%d`; then
    #    mv $Working_dir/`date +%Y%m%d` $Working_dir/`date +%Y%m%d`-1
    #    Working_dir=$Working_dir/`date +%Y%m%d`-2
    #    mkdir -p $Working_dir
    # + handle a third run, etc

    local MCC_dir="$Working_dir"/binary/mediaconch/$Sub_dir
    local MCG_dir="$Working_dir"/binary/mediaconch-gui/$Sub_dir
    local MCS_dir="$Working_dir"/source/mediaconch/$Sub_dir
    local MC_tmp="$Working_dir"/tmp/mediaconch/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MCC_dir"
    rm -fr "$MCG_dir"
    rm -fr "$MCS_dir"
    rm -fr "$MC_tmp"

    mkdir -p "$MCC_dir"
    mkdir -p "$MCG_dir"
    mkdir -p "$MCS_dir"
    mkdir -p "$MC_tmp"

    cd "$MC_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$Source_dir" "$MC_tmp"/upgrade_version/MediaConch_SourceCode
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -o $Version_old -n $Version_new -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -o $Version_old -n $Version_new -wp "$MC_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mc -v $Version_new -wp "$MC_tmp"/prepare_source -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode $PS_target -nc

    if [ "$Target" = "mac" ]; then
        _mac
        mv "$MC_tmp"/prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* "$MCC_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* "$MCG_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _windows > "$Log"/windows.log 2>&1
        else
            echo _windows
        fi
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z "$MCS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        _linux
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}.* "$MCS_dir"
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux
            _mac
            echo _windows > "$Log"/windows.log 2>&1
        else
            _linux
            _mac
            echo _windows
        fi
        mv "$MC_tmp"/prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* "$MCC_dir"
        mv "$MC_tmp"/prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* "$MCG_dir"
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z "$MCS_dir"
        mv "$MC_tmp"/prepare_source/archives/mediaconch_${Version_new}.* "$MCS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MC_tmp"
    fi

}
