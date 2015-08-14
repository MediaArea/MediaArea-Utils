# MediaInfoLib/Release/BuildRelease.sh
# Build a release of MediaInfoLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _build_mac () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd "$MIL_tmp"

    # Clean up
    $sp "cd $RWDir ;
            test -d build || mkdir build ;
            rm -fr build/MediaInfo_DLL*"

    echo
    echo "Compile MIL for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaInfo_DLL_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            tar xJf MediaInfo_DLL_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_DLL_GNU_FromSource ;
            ./SO_Compile.sh --enable-arch-x86_64 --enable-arch-i386 ;
            strip -u -r MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib"

    echo
    echo
    echo "Making the archive..."
    echo

            #cd MediaInfo_DLL_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac ;
            ./mktarball.sh ${Version_new}"

    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2" "$MIL_dir"
    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/Mac/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.xz" "$MIL_dir"

}

function _build_mac_tmp () {

    # This function is a temporay fix for the autotools bug under
    # mac. Check the size to know if the compilation was
    # successful. If not, retry to compile up to 3 times.

    local Try MultiArch

    cd "$MIL_tmp"

    MultiArch=0
    Try=0
    touch "$MIL_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2
    if b.opt.has_flag? --log; then
        until [ `ls -l "$MIL_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq 10 ]; do
            _build_mac >> "$Log"/$Project-mac.log 2>&1
            # Return 1 if MIL is compiled for i386 and x86_64,
            # 0 otherwise
            #MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_DLL_${Version_new}_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            Try=$(($Try + 1))
        done
    else
        until [ `ls -l "$MIL_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq 3 ]; do
            _build_mac
            #MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_DLL_${Version_new}_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library/.libs/libmediainfo.dylib" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            Try=$(($Try + 1))
        done
        # TODO: send a mail if the build fail
        #if [ `ls -l "$MIL_dir"/MediaInfo_DLL_${Version_new}_Mac_i386+x86_64.tar.bz2 |awk '{print $5}'` -lt 4000000 ] || [ $MultiArch -eq 0 ]; then
        #    mail -s "Problem building MIL" someone@mediaarea.net < "The log is http://url/"$Log"/$Project-mac.log"
        #fi
    fi

}

function _build_windows () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $WinSSHPort $WinSSHUser@$WinIP"
    RWDir="c:/Users/almin"

    cd "$MIL_tmp"

    # Clean up
    $sp "c: & chdir $RWDir & rmdir /S /Q build"
    $sp "c: & chdir $RWDir & md build"

    echo
    echo "Compile MIL for windows..."
    echo

}

function btask.BuildRelease.run () {

    # TODO: incrementals snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    MIL_dir="$WDir"/binary/libmediainfo0/$Date
    MILS_dir="$WDir"/source/libmediainfo/$Date
    MIL_tmp="$WDir"/tmp/$Date/mil

    echo
    echo Clean up...
    echo

    rm -fr "$MIL_dir"
    rm -fr "$MILS_dir"
    rm -fr "$MIL_tmp"

    mkdir -p "$MIL_dir"
    mkdir -p "$MILS_dir"
    mkdir -p "$MIL_tmp"

    cd "$MIL_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$SDir" "$MIL_tmp"/upgrade_version/MediaInfoLib
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -sp "$MIL_tmp"/upgrade_version/MediaInfoLib
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mil -o $Version_old -n $Version_new -wp "$MIL_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # TODO: final version = remove -nc
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mil -v $Version_new -wp "$MIL_tmp"/prepare_source -sp "$MIL_tmp"/upgrade_version/MediaInfoLib $PSTarget -nc

    if [ "$Target" = "mac" ]; then
        # Uncomment after the resolution of the autotools bug
        #if b.opt.has_flag? --log; then
        #   _build_mac > "$Log"/$Project-mac.log 2>&1
        #else
        #   _build_mac
        #fi
        _build_mac_tmp
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _build_windows > "$Log"/$Project-windows.log 2>&1
        else
            echo _build_windows
        fi
    fi
    
    if [ "$Target" = "linux" ]; then
        if b.opt.has_flag? --log; then
            echo _build_linux > "$Log"/$Project-linux.log 2>&1
        else
            echo _build_linux
        fi
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            # Uncomment after the resolution of the autotools bug
            #_build_mac > "$Log"/$Project-mac.log 2>&1
            _build_mac_tmp
            echo _build_windows > "$Log"/$Project-windows.log 2>&1
            echo _build_linux > "$Log"/$Project-linux.log 2>&1
        else
            _build_mac_tmp
            echo _build_windows
            echo _build_linux
        fi
    fi

    cd "$MIL_tmp"
    mv prepare_source/archives/MediaInfo_DLL_${Version_new}_GNU_FromSource.* "$MIL_dir"

    if $CleanUp; then
        # Can't rm $WDir/tmp/ or even $WDir/tmp/$Date, because
        # another instance of BS.sh can be running for another
        # project
        rm -fr "$MIL_tmp"
    fi

}
