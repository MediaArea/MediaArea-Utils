# MediaInfo/Release/BuildRelease.sh
# Build a release of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _build_mac_cli () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd "$MI_tmp"

    # Clean up
    $sp "cd $RWDir ;
            test -d build || mkdir build ;
            rm -fr build/MediaInfo_CLI*"

    echo
    echo "Compile MI CLI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            tar xJf MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_CLI_GNU_FromSource ;
            ./CLI_Compile.sh --enable-arch-x86_64 --enable-arch-i386"

    echo
    echo
    echo "DMG stage..."

            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac ;
            ./mkdmg.sh mi cli $Version_new"

    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_CLI_${Version_new}_Mac.dmg" "$MIC_dir"

}

function _build_mac_gui () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd "$MI_tmp"

    # Clean up
    $sp "cd $RWDir ;
            test -d build || mkdir build ;
            rm -fr build/MediaInfo_GUI*"

    echo
    echo "Compile MI GUI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            tar xJf MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_GUI_GNU_FromSource ;
            mkdir -p Shared/Source
            cp -r ../../WxWidgets Shared/Source ;
            ./GUI_Compile.sh --with-wx-static --enable-arch-x86_64"
            # Because wx doesn't compile in 32 bits
            #./GUI_Compile.sh --with-wx-static --enable-arch-x86_64 --enable-arch-i386"

    echo
    echo
    echo "DMG stage..."

            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac ;
            ./mkdmg.sh mi gui $Version_new"

    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_GUI_${Version_new}_Mac.dmg" "$MIG_dir"

}

function _build_mac_tmp () {

    # This function is a temporay fix for the autotools bug under
    # mac. Check the size to know if the compilation was
    # successful. If not, retry to compile up to 3 times.

    local Try MultiArch

    cd "$MI_tmp"

    MultiArch=0
    Try=0
    touch "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg
    if b.opt.has_flag? --log; then
        until [ `ls -l "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq 5 ]; do
            _build_mac_cli >> "$Log"/$Project-mac-cli.log 2>&1
            # Return 1 if MI-cli is compiled for i386 and x86_64,
            # 0 otherwise
            #MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_CLI_${Version_new}_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            Try=$(($Try + 1))
        done
    else
        until [ `ls -l "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] && [ $MultiArch -eq 1 ] || [ $Try -eq 3 ]; do
            _build_mac_cli
            #MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_CLI_${Version_new}_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            MultiArch=`ssh -x -p $MacSSHPort $MacSSHUser@$MacIP "file /Users/mymac/Documents/almin/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI/mediainfo" |grep "Mach-O universal binary with 2 architectures" |wc -l`
            Try=$(($Try + 1))
        done
        # TODO: send a mail if the build fail
        #if [ `ls -l "$MIC_dir"/MediaInfo_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -lt 4000000 ] || [ $MultiArch -eq 0 ]; then
        #    mail -s "Problem building MI-cli" someone@mediaarea.net < "The log is http://url/"$Log"/$Project-mac-cli.log"
        #fi
    fi

    Try=0
    touch "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg
    if b.opt.has_flag? --log; then
        until [ `ls -l "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq 5 ]; do
            _build_mac_gui >> "$Log"/$Project-mac-gui.log 2>&1
            Try=$(($Try + 1))
        done
    else
        until [ `ls -l "$MIG_dir"/MediaInfo_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 4000000 ] || [ $Try -eq 5 ]; do
            _build_mac_gui
            Try=$(($Try + 1))
        done
    fi

}

function _build_windows () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $WinSSHPort $WinSSHUser@$WinIP"
    RWDir="c:/Users/almin"

    cd "$MI_tmp"

    # Clean up
    $sp "c: & chdir $RWDir & rmdir /S /Q build"
    $sp "c: & chdir $RWDir & md build"

    echo
    echo "Compile MI CLI for windows..."
    echo

    scp -P $WinSSHPort prepare_source/archives/mediainfo_${Version_new}_AllInclusive.7z $WinSSHUser@$WinIP:$RWDir/build/mediainfo_${Version_new}_AllInclusive.7z
    $sp "c: & chdir $RWDir/build & \
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
#    scp -P $MacSSHPort prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz
#            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
#    $sp "cd $RWDir/build ;
#            tar xJf MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz ;
#            cd MediaInfo_CLI_GNU_FromSource ;
#            ./CLI_Compile.sh --enable-arch-x86_64 --enable-arch-i386"
#
#    echo
#    echo "Compile MI GUI for mac..."
#    echo
#
#    scp -P $MacSSHPort prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz
#            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
#    $sp "cd $RWDir/build ;
#            tar xJf MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz ;
#            cd MediaInfo_GUI_GNU_FromSource ;
#            mkdir -p Shared/Source
#            cp -r ../../WxWidgets Shared/Source ;
#            ./GUI_Compile.sh --with-wx-static --enable-arch-x86_64"
#            # Because wx doesn't compile in 32 bits
#            #./GUI_Compile.sh --with-wx-static --enable-arch-x86_64 --enable-arch-i386"
#
#    echo
#    echo "Making the dmg..."
#    echo
#
#            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
#            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
#    $sp "cd $RWDir/build ;
#            $KeyChain ;
#            cd MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac ;
#            ./mkdmg.sh mi cli $Version_new ;
#            cd - > /dev/null ;
#            cd MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac ;
#            ./mkdmg.sh mi gui $Version_new"
#
#    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_CLI_${Version_new}_Mac.dmg" mac
#    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_GUI_${Version_new}_Mac.dmg" mac

}

function btask.BuildRelease.run () {

    # TODO: incrementals snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    MIC_dir="$WDir"/binary/mediainfo/$Date
    MIG_dir="$WDir"/binary/mediainfo-gui/$Date
    MIS_dir="$WDir"/source/mediainfo/$Date
    MI_tmp="$WDir"/tmp/$Date/mi

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
        cp -r "$SDir" "$MI_tmp"/upgrade_version/MediaInfo
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -sp "$MI_tmp"/upgrade_version/MediaInfo
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -wp "$MI_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # TODO: final version = remove -nc
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mi -v $Version_new -wp "$MI_tmp"/prepare_source -sp "$MI_tmp"/upgrade_version/MediaInfo $PSTarget -nc

    if [ "$Target" = "mac" ]; then
        # Uncomment after the resolution of the autotools bug
        #if b.opt.has_flag? --log; then
        #   _build_mac_cli > "$Log"/$Project-mac-cli.log 2>&1
        #   _build_mac_gui > "$Log"/$Project-mac-gui.log 2>&1
        #else
        #   _build_mac_cli
        #   _build_mac_gui
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
            #_build_mac_cli > "$Log"/$Project-mac-cli.log 2>&1
            #_build_mac_gui > "$Log"/$Project-mac-gui.log 2>&1
            _build_mac
            echo _build_windows > "$Log"/$Project-windows.log 2>&1
            echo _build_linux > "$Log"/$Project-linux.log 2>&1
        else
            _build_mac_tmp
            echo _build_windows
            echo _build_linux
        fi
    fi

    cd "$MI_tmp"
    mv prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.* "$MIC_dir"
    mv prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.* "$MIG_dir"

    if $CleanUp; then
        # Can't rm $WDir/tmp/ or even $WDir/tmp/$Date, because
        # another instance of BS.sh can be running for another
        # project
        rm -fr "$MI_tmp"
    fi

}
