# MediaConch_SourceCode/Release/BuildRelease.sh
# Build a release of MediaConch

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.html file in the root of the source tree.

function _build_mac () {

    local sp IP

    IP="93.219.124.30"
    # SSH prefix
    sp="ssh -p 2222 mymac@$IP"

    echo
    echo "Build Mac MC CLI..."
    echo

    scp -P 2222 "$WPath/archives/MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz" mymac@$IP:~/Documents/almin/build
    $sp "cd ~/Documents/almin/build ;
            tar xJf MediaConch_CLI_${Version_new}_GNU_FromSource.tar.xz"

    $sp "cd ~/Documents/almin/build ;
            cp -r ../libxml2 MediaConch_CLI_GNU_FromSource"
    $sp "cd ~/Documents/almin/build/MediaConch_CLI_GNU_FromSource ;
            ./CLI_Compile.sh"
    $sp "cd ~/Documents/almin/build/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac ;
            ./mkdmg.sh mc cli $Version_new"

exit

    echo
    echo "Build Mac MC GUI..."
    echo

    scp -P 2222 "$WPath/archives/MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz" mymac@$IP:~/Documents/almin/build
    $sp "cd ~/Documents/almin/build ;
            tar xJf MediaConch_GUI_${Version_new}_GNU_FromSource.tar.xz"

    $sp "cd ~/Documents/almin/build ;
            cp -r ../libxml2 MediaConch_GUI_GNU_FromSource"
    $sp "cd ~/Documents/almin/build/MediaConch_GUI_GNU_FromSource ;
            PATH=$PATH:~/Qt/5.3/clang_64/bin ./GUI_Compile.sh"
    $sp "cd ~/Documents/almin/build/MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac ;
            PATH=$PATH:~/Qt/5.3/clang_64/bin ./mkdmg.sh mc gui $Version_new"

    echo
    echo "Fetching back the dmg..."
    echo

    scp -P 2222 "mymac@$IP:~/Documents/almin/build/MediaConch_CLI_GNU_FromSource/MediaConch/Project/Mac/*dmg" $WPath
    scp -P 2222 "mymac@$IP:~/Documents/almin/build/MediaConch_GUI_GNU_FromSource/MediaConch/Project/Mac/*dmg" $WPath

}

function btask.BuildRelease.run () {

    rm -fr "$WPath/upgrade_version"
    mkdir "$WPath/upgrade_version"
    cd $(b.get bang.working_dir)/../upgrade_version
    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p mc -o $Version_current -n $Version_new -w "$WPath/upgrade_version"

    cd $(b.get bang.working_dir)/../prepare_source
    $(b.get bang.src_path)/bang run PrepareSource.sh -p mc -v $Version_new -all -w "$WPath" -s "$WPath/upgrade_version/MediaConch_SourceCode" -nc

    if [ "$Target" = "mac" ]; then
        _build_mac
    fi
    if [ "$Target" = "windows" ]; then
        echo _build_windows
    fi
    if [ "$Target" = "linux" ]; then
        echo _build_linux
    fi
    if [ "$Target" = "all" ]; then
        _build_mac
        echo _build_windows
        echo _build_linux
    fi

}
