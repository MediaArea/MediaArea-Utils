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

    test -e "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 && rm "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$Mac_working_dir/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 "$MILB_dir"
    test -e "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz && rm "$MILB_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz
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

    # Create Debian packages and dsc
    deb_obs "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}.orig.tar.xz

    cp prepare_source/MIL/MediaInfoLib/Project/GNU/libmediainfo.spec $OBS_package
    cp prepare_source/MIL/MediaInfoLib/Project/GNU/PKGBUILD $OBS_package

    update_PKGBUILD "$MIL_tmp"/$OBS_package libmediainfo_${Version_new}.orig.tar.xz PKGBUILD

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
    echo python Handle_OBS_results.py $* $OBS_project MediaInfoLib $Version_new "$MILB_dir"
    echo

    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $* $OBS_project MediaInfoLib $Version_new "$MILB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &

}

function btask.BuildRelease.run () {

    local UV_flags
    local MILB_dir="$Working_dir"/binary/libmediainfo0/$Sub_dir
    local MILS_dir="$Working_dir"/source/libmediainfo/$Sub_dir
    local MIL_tmp="$Working_dir"/tmp/libmediainfo/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$MIL_tmp"

    mkdir -p "$MILB_dir"

    if [ $(b.opt.get_opt --rebuild) ] ; then
        _linux --filter $(b.opt.get_opt --rebuild)
        exit 0
    fi

    mkdir -p "$MILS_dir"
    mkdir -p "$MIL_tmp"

    cd "$MIL_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$MIL_tmp"/upgrade_version/MediaInfoLib
    else
        pushd "$MIL_tmp"/upgrade_version
        git clone "$Repo"
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd "$MIL_tmp"/upgrade_version/MediaInfoLib
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $MIL_tmp/upgrade_version/MediaInfoLib/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if [ $(b.opt.get_opt --zl-version) ]; then
         UV_flags="-zv $(sanitize_arg $(b.opt.get_opt --zl-version))"
    fi

    if b.opt.has_flag? --commit ; then
        UV_flags="${UV_flags} -c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -n $Version_new $UV_flags -sp "$MIL_tmp"/upgrade_version/MediaInfoLib

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    find "$MILS_dir" -mindepth 1 -delete
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
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
            echo _windows >"$Log"/windows.log 2>"$Log"/windows-error.log
        else
            _linux
            _mac
            echo _windows
        fi
        mv "$MIL_tmp"/prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MILB_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}_AllInclusive.7z "$MILS_dir"
        mv "$MIL_tmp"/prepare_source/archives/libmediainfo_${Version_new}.* "$MILS_dir"
    fi

    if $Clean_up; then
        rm -fr "$MIL_tmp"
    fi

}
