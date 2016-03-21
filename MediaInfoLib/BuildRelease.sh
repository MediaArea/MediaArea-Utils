# MediaInfoLib/Release/BuildRelease.sh
# Build a release of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_mil () {

    cd "$MIL_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir ;
            cd $Mac_working_dir ;
            rm -fr MediaInfo_DLL*"

    echo
    echo "Compile MIL for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir ;
            tar xf MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_DLL_GNU_FromSource ;
            MediaInfoLib/Project/Mac/BR_extension_SO.sh ;
            $Key_chain ;
            cd MediaInfoLib/Project/Mac ;
            ./Make_tarball.sh ${Version_new}"

    if ! b.opt.has_flag? --snapshot; then
        echo
        echo
        echo "Preparing the dylib for Xcode..."
        echo
        $SSHP "cd $Mac_working_dir ;
                test -d dylib_for_xcode || mkdir dylib_for_xcode ;
                rm -fr dylib_for_xcode/* ;
                cp MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz dylib_for_xcode"
    fi

    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 "$MILB_dir"
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz "$MILB_dir"

}

function _mac () {

    # This function test the success of the compilation by testing
    # size and multiarch. If fail, retry to compile up to 3 times.

    local SSHP NbTry Try MultiArch

    # SSH prefix
    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"
    NbTry=3

    cd "$MIL_tmp"

    MultiArch=0
    Try=0
    touch "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2
    until [ `ls -l "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq $NbTry ]; do
        _mac_mil
        # Return 1 if MIL is compiled for i386 and x86_64,
        # 0 otherwise
        MultiArch=`ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP "file $Mac_working_dir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
        Try=$(($Try + 1))
    done

    # Send a mail if the build fail

    # If the dylib dmg is less than 4 Mo
    if [ `ls -l "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -lt 4000000 ] || [ $MultiArch -eq 0 ]; then
        if b.opt.has_flag? --log; then
            xz --keep --force -9e $Log/mac.log
            if ! [ -z "$Email_CC" ]; then
                echo "The dylib dmg is less than 4 Mo. The log is http://url/$Log/mac.log" | mailx -s "[BR mac] Problem building MIL" -a $Log/mac.log.xz -c "$Email_CC" $Email_to
            else
                echo "The dylib dmg is less than 4 Mo. The log is http://url/$Log/mac.log" | mailx -s "[BR mac] Problem building MIL" -a $Log/mac.log.xz $Email_to
            fi
        else
            if ! [ -z "$Email_CC" ]; then
                echo "The dylib dmg is less than 4 Mo" | mailx -s "[BR mac] Problem building MIL" -c "$Email_CC" $Email_to
            else
                echo "The dylib dmg is less than 4 Mo" | mailx -s "[BR mac] Problem building MIL" $Email_to
            fi
        fi
    fi

}

function _windows () {

    local sp RWorking_dir

    # SSH prefix
    SSHP="ssh -x -p $Win_SSH_port $Win_SSH_user@$Win_IP"
    RWorking_dir="c:/Users/almin"

    cd "$MIL_tmp"

    # Clean up
    $SSHP "c: & chdir $RWorking_dir & rmdir /S /Q build"
    $SSHP "c: & chdir $RWorking_dir & md build"

    echo
    echo "Compile MIL for windows..."
    echo

}

function _obs () {

    local OBS_package="$OBS_project/MediaInfoLib"

    cd "$MIL_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/libmediainfo_${Version_new}.tar.xz $OBS_package/libmediainfo_${Version_new}.orig.tar.xz
    cp prepare_source/archives/libmediainfo_${Version_new}.tar.gz $OBS_package

    cd $OBS_package
    tar xf libmediainfo_${Version_new}.orig.tar.xz
    mv MediaInfoLib/debian .
    rm -fr MediaInfoLib
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libmediainfo_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/MIL/MediaInfoLib/Project/GNU/libmediainfo.spec $OBS_package
    cp prepare_source/MIL/MediaInfoLib/Project/GNU/libmediainfo.dsc $OBS_package/libmediainfo_${Version_new}-1.dsc

    update_DSC "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}.orig.tar.xz libmediainfo_${Version_new}-1.dsc
    update_DSC "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}-1.debian.tar.xz libmediainfo_${Version_new}-1.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb () {

    # This function build the source on OBS for a specific debian
    # version.

    local Deb_version="$1"
    local OBS_package="$OBS_project/MediaInfoLib_$Deb_version"

    cd "$MIL_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/libmediainfo_${Version_new}.tar.xz $OBS_package
    cd $OBS_package
    tar xf libmediainfo_${Version_new}.tar.xz
    rm -fr libmediainfo_${Version_new}.tar.xz
    rm -fr MediaInfoLib/debian ; mv MediaInfoLib/Project/OBS/${Deb_version}.debian MediaInfoLib/debian
    cp -r MediaInfoLib/debian .
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libmediainfo_${Version_new}.orig.tar.xz MediaInfoLib)
    rm -fr MediaInfoLib
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libmediainfo_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/MIL/MediaInfoLib/Project/OBS/${Deb_version}.dsc $OBS_package/libmediainfo_${Version_new}-1.dsc

    update_DSC "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}.orig.tar.xz libmediainfo_${Version_new}-1.dsc
    update_DSC "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}-1.debian.tar.xz libmediainfo_${Version_new}-1.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb6 () {

    # This function build the source on OBS for Debian 6.

    local OBS_package="$OBS_project/MediaInfoLib_deb6"

    cd "$MIL_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/libmediainfo_${Version_new}.tar.gz $OBS_package
    cd $OBS_package
    tar xf libmediainfo_${Version_new}.tar.gz
    rm -fr MediaInfoLib/debian ; mv MediaInfoLib/Project/OBS/deb6.debian MediaInfoLib/debian
    (GZIP=-9 tar -cz --owner=root --group=root -f libmediainfo_${Version_new}.tar.gz MediaInfoLib)
    rm -fr MediaInfoLib
    cd ../..

    cp prepare_source/MIL/MediaInfoLib/Project/OBS/deb6.dsc $OBS_package/libmediainfo_${Version_new}.dsc

    update_DSC "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}.tar.gz libmediainfo_${Version_new}.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _linux () {

    _obs
    _obs_deb6
    _obs_deb deb9
    echo
    echo Launch in background the python script which check
    echo the build results and download the packages...
    echo
    echo The command line is:
    echo python Handle_OBS_results.py $OBS_project MediaInfoLib $Version_new "$MILB_dir"
    echo

    cd $(b.get bang.working_dir)
    python Handle_OBS_results.py $OBS_project MediaInfoLib $Version_new "$MILB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfoLib_deb6 $Version_new "$MILB_dir" >"$Log"/obs_deb6.log 2>"$Log"/obs_deb6-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project MediaInfoLib_deb9 $Version_new "$MILB_dir" >"$Log"/obs_deb9.log 2>"$Log"/obs_deb9-error.log &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $Working_dir/`date +%Y%m%d`; then
    #    mv $Working_dir/`date +%Y%m%d` $Working_dir/`date +%Y%m%d`-1
    #    Working_dir=$Working_dir/`date +%Y%m%d`-2
    #    mkdir -p $Working_dir
    # + handle a third run, etc
        
    local MILB_dir="$Working_dir"/binary/libmediainfo0/$Sub_dir
    local MILS_dir="$Working_dir"/source/libmediainfo/$Sub_dir
    local MIL_tmp="$Working_dir"/tmp/libmediainfo/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MILB_dir"
    rm -fr "$MILS_dir"
    rm -fr "$MIL_tmp"

    mkdir -p "$MILB_dir"
    mkdir -p "$MILS_dir"
    mkdir -p "$MIL_tmp"

    cd "$MIL_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$Source_dir" "$MIL_tmp"/upgrade_version/MediaInfoLib
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -sp "$MIL_tmp"/upgrade_version/MediaInfoLib
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -wp "$MIL_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mil -v $Version_new -wp "$MIL_tmp"/prepare_source -sp "$MIL_tmp"/upgrade_version/MediaInfoLib $PS_target -nc

    if [ "$Target" = "mac" ]; then
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi
        mv "$MIL_tmp"/prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MILB_dir"
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            echo _windows
        fi
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}_AllInclusive.7z "$MILS_dir"
    fi
    
    if [ "$Target" = "linux" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}.* "$MILS_dir"
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
            echo _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _mac
            echo _windows
            _linux
        fi
        mv "$MIL_tmp"/prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MILB_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}_AllInclusive.7z "$MILS_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}.* "$MILS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MIL_tmp"
    fi

}
