# MediaConch_SourceCode/Release/BuildRelease.sh
# Build a release of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _build_mac_cli () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd "$MC_tmp"

    # Clean up
    $sp "cd $RWDir ;
            test -d build || mkdir build ;
            rm -fr build/MediaConch_CLI*"

    echo
    echo "Compile MC CLI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaConch_CLI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            tar xJf MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_CLI_GNU_FromSource ;
            cp -r ../../libxml2 . ;
            ./CLI_Compile.sh"
            # Because the libxml2 doesn't compile in 32 bits
            #./CLI_Compile.sh --enable-arch-x86_64 --enable-arch-i386"

            # configure xml :
            #./configure --disable-shared --enable-static --disable-ipv6 --without-ftp --without-http --without-html --without-c14n --without-catalog --with-xpath --without-xptr --without-xinclude --without-iconv --without-icu --without-iso8859x --without-zlib --without-lzma --without-memdebug --without-rundebug --without-regexps --without-modules --with-tree --without-writer --with-pattern --with-push --without-valid --with-sax1 --without-legacy --with-output --without-schemas --with-schematron --without-python LAGS=" -mmacosx-version-min=10.5" CXXFLAGS=" -mmacosx-version-min=10.5" LDFLAGS=" -mmacosx-version-min=10.5"

    echo
    echo
    echo "DMG stage..."

            #cd MediaConch_CLI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac ;
            ./mkdmg.sh mc cli $Version_new"

    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_CLI_${Version_new}_Mac.dmg" "$MCC_dir"

}


function _build_mac_gui () {

    local sp RWDir

    # SSH prefix
    sp="ssh -x -p $MacSSHPort $MacSSHUser@$MacIP"
    RWDir="/Users/mymac/Documents/almin"

    cd "$MC_tmp"

    # Clean up
    $sp "cd $RWDir ;
            test -d build || mkdir build ;
            rm -fr build/MediaConch_GUI*"

    echo
    echo "Compile MC GUI for mac..."
    echo

    scp -P $MacSSHPort prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz $MacSSHUser@$MacIP:$RWDir/build/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz
            #cd MediaConch_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            tar xJf MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz ;
            cd MediaConch_GUI_GNU_FromSource ;
            cp -r ../../libxml2 . ;
            PATH=$PATH:~/Qt/5.3/clang_64/bin ./GUI_Compile.sh"

    echo
    echo
    echo "DMG stage..."

            #cd MediaConch_GUI_${Version_new}_GNU_FromSource ;
    $sp "cd $RWDir/build ;
            $KeyChain ;
            cd MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac ;
            PATH=$PATH:~/Qt/5.3/clang_64/bin ./mkdmg.sh mc gui $Version_new"

    scp -P $MacSSHPort "$MacSSHUser@$MacIP:$RWDir/build/MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac/MediaConch_GUI_${Version_new}_Mac.dmg" "$MCG_dir"

}

function _build_mac () {

    # This function is a temporay fix for the autotools bug under
    # mac. Check the size to know if the compilation was
    # successful. If not, retry to compile up to 3 times.

    local Try MultiArch

    cd "$MC_tmp"

    Try=0
    touch "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg
    if b.opt.has_flag? --log; then
        until [ `ls -l "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 2500000 ] || [ $Try -eq 5 ]; do
            _build_mac_cli >> "$Log"/$Project-mac-cli.log 2>&1
            Try=$(($Try + 1))            
        done
    else
        until [ `ls -l "$MCC_dir"/MediaConch_CLI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 2500000 ] || [ $Try -eq 5 ]; do
            _build_mac_cli
            Try=$(($Try + 1))
        done
    fi

    Try=0
    touch "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg
    if b.opt.has_flag? --log; then
        until [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 10000000 ] || [ $Try -eq 5 ]; do
            _build_mac_gui >> "$Log"/$Project-mac-gui.log 2>&1
            Try=$(($Try + 1))
        done
    else
        until [ `ls -l "$MCG_dir"/MediaConch_GUI_${Version_new}_Mac.dmg |awk '{print $5}'` -gt 10000000 ] || [ $Try -eq 5 ]; do
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

    cd "$MC_tmp"

    # Clean up
    $sp "c: & chdir $RWDir & rmdir /S /Q build & md build"

    echo
    echo "Compile MC CLI for windows..."
    echo

    scp -P $WinSSHPort prepare_source/archives/mediaconch_${Version_new}_AllInclusive.7z $WinSSHUser@$WinIP:$RWDir/build/mediaconch_${Version_new}_AllInclusive.7z
            #xcopy /E /I /Q ..\\libxml2 mediaconch_${Version_new}_AllInclusive\\libxml2 & \
    $sp "c: & chdir $RWDir/build & \
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

function btask.BuildRelease.run () {

    # TODO: incrementals snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc

    MCC_dir="$WDir"/binary/mediaconch/$Date
    MCG_dir="$WDir"/binary/mediaconch-gui/$Date
    MCS_dir="$WDir"/source/mediaconch/$Date
    MC_tmp="$WDir"/tmp/$Date/mc

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
        # Uncomment after the resolution of the autotools bug
        #if b.opt.has_flag? --log; then
        #   _build_mac_cli > "$Log"/$Project-mac-cli.log 2>&1
        #   _build_mac_gui > "$Log"/$Project-mac-gui.log 2>&1
        #else
        #   _build_mac_cli
        #   _build_mac_gui
        #fi
        _build_mac
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
            _build_mac
            echo _build_windows
            echo _build_linux
        fi
    fi

    cd "$MC_tmp"
    mv prepare_source/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.* $MCC_dir
    mv prepare_source/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.* $MCG_dir

    if $CleanUp; then
        # Can't rm $WDir/tmp/ or even $WDir/tmp/$Date, because
        # another instance of BS.sh can be running for another
        # project
        rm -fr "$MC_tmp"
    fi

}
