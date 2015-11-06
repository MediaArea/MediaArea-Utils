# MediaConch_SourceCode/Release/BuildRelease.sh
# Build a release of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $MacWDir || mkdir $MacWDir ;
            cd $MacWDir ;
            rm -fr MediaConch_CLI*"

    echo
    echo "Compile MC CLI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$MacWDir/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz

            #cd MediaConch_CLI_${Version_new}_GNU_FromSource ;
    $SSHP "cd $MacWDir ;
            tar xf MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_CLI_GNU_FromSource ;
            MediaConch/Project/Mac/build_CLI.sh ;
            $KeyChain ;
            cd MediaConch/Project/Mac ;
            ./mkdmg.sh mc cli $Version_new"

    scp -P $MacSSHPort $MacSSHUser@$MacIP:$MacWDir/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_CLI_${Version_new}_Mac.dmg "$MCC_dir"

}

function _mac_gui () {

    cd "$MC_tmp"

    # Clean up
    $SSHP "test -d $MacWDir || mkdir $MacWDir ;
            cd $MacWDir ;
            rm -fr MediaConch_GUI*"

    echo
    echo "Compile MC GUI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$MacWDir/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz

            #cd MediaConch_GUI_${Version_new}_GNU_FromSource ;
    $SSHP "cd $MacWDir ;
            tar xf MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_GUI_GNU_FromSource ;
            MediaConch/Project/Mac/build_GUI.sh ;
            $KeyChain ;
            cd MediaConch/Project/Mac ;
            ./mkdmg.sh mc gui $Version_new"

    scp -P $MacSSHPort $MacSSHUser@$MacIP:$MacWDir/MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_GUI_${Version_new}_Mac.dmg "$MCG_dir"

}

function _mac () {

    # This function test the success of the compilation by testing
    # the size. If fail, retry to compile up to 3 times.

    local SSHP NbTry Try

    # SSH prefix
    SSHP="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
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
            echo "The log is http://url/$Log/mac-cli.log.xz" | mailx -s "[BR.sh mac] Problem building MC-cli" -a $Log/mac-cli.log.xz -c "$MailCC" $Mail
        else
            echo "The log is http://url/$Log/mac-cli.log.xz" | mailx -s "[BR.sh mac] Problem building MC-cli" -a $Log/mac-cli.log.xz $Mail
        fi
    fi

    if [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 10000000 ]; then
        xz -9e $Log/mac-gui.log
        if ! [ -z "$MailCC" ]; then
            echo "The log is http://url/$Log/mac-gui.log.xz" | mailx -s "[BR.sh mac] Problem building MC-gui" -a $Log/mac-gui.log.xz -c "$MailCC" $Mail
        else
            echo "The log is http://url/$Log/mac-gui.log.xz" | mailx -s "[BR.sh mac] Problem building MC-gui" -a $Log/mac-gui.log.xz $Mail
        fi
    fi

}

function _windows () {

    local SSHP RWDir

    # SSH prefix
    SSHP="ssh -x -p $WinSSHPort $WinSSHUser@$WinIP"
    RWDir="c:/Users/almin"

    cd "$MC_tmp"

    # Clean up
    $SSHP "c: & chdir $RWDir & rmdir /S /Q build & md build"

    echo
    echo "Compile MC CLI for windows..."
    echo

    scp -P $WinSSHPort prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z $WinSSHUser@$WinIP:$RWDir/build/mediaconch_${Version_new}_AllInclusive.7z
            #xcopy /E /I /Q ..\\libxml2 mediaconch_${Version_new}_AllInclusive\\libxml2 & \
    $SSHP "c: & chdir $RWDir/build & \
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

    local OBS_Package="$OBS_Project/MediaConch"

    cd "$MC_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_Package

    # Clean up
    rm -f $OBS_Package/*

    cp prepare_source/archives/mediaconch_${Version_new}.tar.xz $OBS_Package
    cp prepare_source/archives/mediaconch_${Version_new}.tar.gz $OBS_Package
    #cp prepare_source/MC/MediaConch_${Version_new}/Project/GNU/mediaconch.spec $OBS_Package
    #cp prepare_source/MC/MediaConch_${Version_new}/Project/GNU/mediaconch.dsc $OBS_Package/mediaconch_${Version_new}.dsc
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.spec $OBS_Package
    cp prepare_source/MC/MediaConch/Project/GNU/mediaconch.dsc $OBS_Package/mediaconch_${Version_new}.dsc

    update_DSC "$MC_tmp"/$OBS_Package mediaconch_${Version_new}.tar.xz mediaconch_${Version_new}.dsc

    cd $OBS_Package
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
    python update_Linux_DB.py $OBS_Project MediaConch $Version_new "$MCC_dir" "$MCG_dir" > "$Log"/obs_python.log 2>&1 &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc

    local MCC_dir="$WDir"/binary/mediaconch/$subDir
    local MCG_dir="$WDir"/binary/mediaconch-gui/$subDir
    local MCS_dir="$WDir"/source/mediaconch/$subDir
    local MC_tmp="$WDir"/tmp/mediaconch/$subDir

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
        cp -r "$SDir" "$MC_tmp"/upgrade_version/MediaConch_SourceCode
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -o $Version_old -n $Version_new -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -o $Version_old -n $Version_new -wp "$MC_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # TODO: final version = remove -nc
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mc -v $Version_new -wp "$MC_tmp"/prepare_source -sp "$MC_tmp"/upgrade_version/MediaConch_SourceCode $PSTarget -nc

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

    if $CleanUp; then
        rm -fr "$MC_tmp"
    fi

}
