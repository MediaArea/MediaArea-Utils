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
        if b.opt.has_flag? --log; then
            _mac_cli >> "$Log"/mac-cli.log 2>&1
        else
            _mac_cli
        fi
        # Return 1 if MI-cli is compiled for i386 and x86_64,
        # 0 otherwise
        MultiArch=`ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP "file $Mac_working_dir/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        Try=$(($Try + 1))
    done

    Try=0
    touch "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg
    until [ `ls -l "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq $NbTry ]; do
        if b.opt.has_flag? --log; then
            _mac_gui >> "$Log"/mac-gui.log 2>&1
        else
            _mac_gui
        fi
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

    local SSHP RWorking_dir

    # SSH prefix
    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    RWorking_dir="c:/Users/almin"

    cd "$MI_tmp"

    # Clean up
    $SSHP "c: & chdir $RWorking_dir & rmdir /S /Q build"
    $SSHP "c: & chdir $RWorking_dir & md build"

    echo
    echo "Compile MI CLI for windows..."
    echo

    scp -P $Win_SSH_port prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z $Win_SSH_user@$Win_IP:$RWorking_dir/build/mediainfo_${Version_new}_AllInclusive.7z
    $SSHP "c: & chdir $RWorking_dir/build & \
            c:/\"Program Files\"/7-Zip/7z x mediainfo_${Version_new}_AllInclusive.7z & \

"
#            copy /Y ..\\MediaInfo.vcxproj mediainfo_AllInclusive\\MediaInfo\\Project\\MSVC2013\\CLI & \
#            copy /Y ..\\MediaInfoLib.vcxproj mediainfo_AllInclusive\\MediaInfoLib\\Project\\MSVC2013\\Library & \

#cd "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\bin\amd64"
#%comspec% /k ""C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"" amd64
#cd C:\Users\almin\build\mediainfo_AllInclusive\MediaInfo\Project\MSVC2013\CLI
#msbuild MediaInfo.vcxproj


#    echo
#    echo "Compile MI CLI for mac..."
#    echo
#
#    scp -P $Mac_SSH_port prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$RWorking_dir/build/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz
#            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
#    $SSHP "cd $RWorking_dir/build ;
#            tar xf MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz ;
#            cd MediaInfo_CLI_GNU_FromSource ;
#            ./CLI_Compile.sh --enable-arch-x86_64 --enable-arch-i386"
#
#    echo
#    echo "Compile MI GUI for mac..."
#    echo
#
#    scp -P $Mac_SSH_port prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$RWorking_dir/build/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz
#            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
#    $SSHP "cd $RWorking_dir/build ;
#            tar xf MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz ;
#            cd MediaInfo_GUI_GNU_FromSource ;
#            mkdir -p Shared/Source
#            cp -r ../../WxWidgets Shared/Source ;
#            ./GUI_Compile.sh --with-wx-static --enable-arch-x86_64"
#            # Because wx doesn’t compile in 32 bits
#            #./GUI_Compile.sh --with-wx-static --enable-arch-x86_64 --enable-arch-i386"
#
#    echo
#    echo "Making the dmg..."
#    echo
#
#            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
#            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
#    $SSHP "cd $RWorking_dir/build ;
#            $Key_chain ;
#            cd MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac ;
#            ./mkdmg.sh mi cli $Version_new ;
#            cd - > /dev/null ;
#            cd MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac ;
#            ./mkdmg.sh mi gui $Version_new"
#
#    scp -P $Mac_SSH_port "$Mac_SSH_user@$Mac_IP:$RWorking_dir/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_CLI_${Version_new}_Mac.dmg" mac
#    scp -P $Mac_SSH_port "$Mac_SSH_user@$Mac_IP:$RWorking_dir/build/MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_GUI_${Version_new}_Mac.dmg" mac

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

    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}.orig.tar.xz mediainfo_${Version_new}-1.dsc
    update_DSC "$MI_tmp"/$OBS_package mediainfo_${Version_new}-1.debian.tar.xz mediainfo_${Version_new}-1.dsc

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

function _linux () {

    if b.opt.has_flag? --log; then
        _obs > "$Log"/linux.log 2>&1
        _obs_deb deb9 >> "$Log"/linux.log 2>&1
        _obs_deb deb7 >> "$Log"/linux.log 2>&1
        _obs_deb6 >> "$Log"/linux.log 2>&1
    else
        _obs
        _obs_deb deb9
        _obs_deb deb7
        _obs_deb6
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
        echo The command line is:
        echo python Handle_OBS_results.py $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir"
        echo

    fi

    cd $(b.get bang.working_dir)
    python Handle_OBS_results.py $OBS_project MediaInfo $Version_new "$MIC_dir" "$MIG_dir" > "$Log"/obs_main.log 2>&1 & 
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb9 $Version_new "$MIC_dir" "$MIG_dir" > "$Log"/obs_deb9.log 2>&1 &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb7 $Version_new "$MIC_dir" "$MIG_dir" > "$Log"/obs_deb7.log 2>&1 &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfo_deb6 $Version_new "$MIC_dir" "$MIG_dir" > "$Log"/obs_deb6.log 2>&1 &

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

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$Source_dir" "$MI_tmp"/upgrade_version/MediaInfo
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -sp "$MI_tmp"/upgrade_version/MediaInfo
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -wp "$MI_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mi -v $Version_new -wp "$MI_tmp"/prepare_source -sp "$MI_tmp"/upgrade_version/MediaInfo $PS_target -nc

    if [ "$Target" = "mac" ]; then
        _mac
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _windows > "$Log"/windows.log 2>&1
        else
            echo _windows
        fi
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z "$MIS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        _linux
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}.* "$MIS_dir"
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
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
        mv "$MI_tmp"/prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z "$MIS_dir"
        mv "$MI_tmp"/prepare_source/archives/mediainfo_${Version_new}.* "$MIS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MI_tmp"
    fi

}
