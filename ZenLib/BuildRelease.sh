# ZenLib/Release/BuildRelease.sh
# Build a release of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _build_linux () {

    local OBS_Repo="home:almin/ZenLib" State=1

    cd "$ZL_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_Repo

    # Clean up
    rm -f $OBS_Repo/*

    cp prepare_source/archives/libzen_${Version_new}.tar.xz $OBS_Repo
    cp prepare_source/archives/libzen_${Version_new}.tar.gz $OBS_Repo/libzen_${Version_new}-1.tar.gz
    #cp prepare_source/ZL/ZenLib_${Version_new}/Project/GNU/libzen.spec $OBS_Repo
    #cp prepare_source/ZL/ZenLib_${Version_new}/Project/GNU/libzen.dsc $OBS_Repo/libzen_${Version_new}.dsc
    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.spec $OBS_Repo
    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.dsc $OBS_Repo/libzen_${Version_new}.dsc

    update_DSC "$ZL_tmp"/$OBS_Repo libzen_${Version_new}.tar.xz libzen_${Version_new}.dsc

    echo
    echo "Build on OBS..."
    echo

    cd $OBS_Repo
    osc addremove *
    osc commit -n

    #until [ $State -eq 0 ]; do
    #    sleep 600
    #    State=`osc results $OBS_Repo |awk '{print $3}' |grep scheduled |grep finished |grep failed |wc -l`
    #done

    # At this point, each package will be either succeeded or
    # failed : python script to update the DB, get the binaries and
    # generate the download webpage
    # Will use :
    #osc results $OBS_Repo |awk '{print $1,$3}' |grep succeeded
    #osc results $OBS_Repo |awk '{print $1,$3}' |grep failed
    #osc getbinaries Debian_7.0 i586

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    ZLB_dir="$WDir"/binary/libzen0/$Date
    ZLS_dir="$WDir"/source/libzen/$Date
    ZL_tmp="$WDir"/tmp/libzen/$Date

    echo
    echo Clean up...
    echo

    rm -fr "$ZLB_dir"
    rm -fr "$ZLS_dir"
    rm -fr "$ZL_tmp"

    mkdir -p "$ZLB_dir"
    mkdir -p "$ZLS_dir"
    mkdir -p "$ZL_tmp"

    cd "$ZL_tmp"
    rm -fr upgrade_version
    rm -fr prepare_source
    mkdir upgrade_version
    mkdir prepare_source

    cd $(b.get bang.working_dir)/../upgrade_version
    if [ $(b.opt.get_opt --source-path) ]; then
        cp -r "$SDir" "$ZL_tmp"/upgrade_version/ZenLib
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p zl -o $Version_old -n $Version_new -sp "$ZL_tmp"/upgrade_version/ZenLib
    else
        $(b.get bang.src_path)/bang run UpgradeVersion.sh -p zl -o $Version_old -n $Version_new -wp "$ZL_tmp"/upgrade_version
    fi

    cd $(b.get bang.working_dir)/../prepare_source
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p zl -v $Version_new -wp "$ZL_tmp"/prepare_source -sp "$ZL_tmp"/upgrade_version/ZenLib -sa -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            echo _build_linux > "$Log"/linux.log 2>&1
        else
            echo _build_linux
        fi
    cp "$ZL_tmp"/prepare_source/archives/libzen_${Version_new}.* "$ZLS_dir"
    fi

    if $CleanUp; then
        # Can't rm $WDir/tmp/ or even $WDir/tmp/$Date, because
        # another instance of BS.sh can be running for another
        # project
        rm -fr "$ZL_tmp"
    fi

}
