# MediaInfo/Release/BuildRelease.sh
# Build a release of MediaInfo

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _build_mac () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd $WDir

    # Clean up
    $sp "cd $RWDir/ ;
            test -d build || mkdir build ;
            rm -fr build/MediaInfo_*"

    echo
    echo "Compile MI CLI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            tar xJf MediaInfo_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_CLI_GNU_FromSource ;
            ./CLI_Compile.sh --enable-arch-i386 --enable-arch-x86_64"

    echo
    echo "Compile MI GUI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            tar xJf MediaInfo_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaInfo_GUI_GNU_FromSource ;
            mkdir -p Shared/Source
            cp -r ../../WxWidgets Shared/Source ;
            ./GUI_Compile.sh --with-wx-static --enable-arch-i386 --enable-arch-x86_64"

    echo
    echo "Making the dmg..."
    echo

            #cd MediaInfo_CLI_${Version_new}_GNU_FromSource ;
            #cd MediaInfo_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac ;
            ./mkdmg.sh mi cli $Version_new ;
            cd - > /dev/null ;
            cd MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac ;
            ./mkdmg.sh mi gui $Version_new"

    mkdir mac
    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_CLI_${Version_new}_Mac.dmg" mac
    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaInfo_GUI_GNU_FromSource/MediaInfo/Project/Mac/MediaInfo_GUI_${Version_new}_Mac.dmg" mac

}

function _build_windows () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $WinSSHPort $WinSSHUser@$WinIP"
    RWDir="c:/Users/almin"

    cd $WDir

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

}

function btask.BuildRelease.run () {

    # TODO: incrementals snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    WDir="$WDir"/$Date/mi
    rm -fr $WDir
    mkdir -p $WDir
    cd $WDir

    echo
    echo Clean up...
    echo

    rm -fr upgrade_version
    rm -fr prepare_source
    rm -fr archives
    rm -fr mac

    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mi -o $Version_old -n $Version_new -w "$WDir/upgrade_version"

    cd $(b.get bang.working_dir)/../prepare_source
    # TODO: final version = remove -nc
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mi -v $Version_new -all -s "$WDir/upgrade_version/MediaInfo" -w "$WDir/prepare_source" $PSTarget -nc

    if [ "$Target" = "mac" ]; then
        if b.opt.has_flag? --log; then
            _build_mac > "$WDir"/../log/$Date-$Project-mac.log 2>&1
        else
            _build_mac
        fi
    fi

    if [ "$Target" = "windows" ]; then
        if b.opt.has_flag? --log; then
            echo _build_windows > "$WDir"/../log/$Date-$Project-windows.log 2>&1
        else
            echo _build_windows
        fi
    fi
    
    if [ "$Target" = "linux" ]; then
        if b.opt.has_flag? --log; then
            echo _build_linux > "$WDir"/../log/$Date-$Project-linux.log 2>&1
        else
            echo _build_linux
        fi
    fi
    
    if [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _build_mac > "$WDir"/../log/$Date-$Project-mac.log 2>&1
            echo _build_windows > "$WDir"/../log/$Date-$Project-windows.log 2>&1
            echo _build_linux > "$WDir"/../log/$Date-$Project-linux.log 2>&1
        else
            _build_mac
            echo _build_windows
            echo _build_linux
        fi
    fi

    cd $WDir
    mv prepare_source/archives .

    if $CleanUp; then
        rm -fr upgrade_version
        rm -fr prepare_source
    fi

}
