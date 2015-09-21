# ZenLib/Release/BuildRelease.sh
# Build a release of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _obs () {

    local OBS_Package="$OBS_Project/ZenLib"

    cd "$ZL_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_Package

    # Clean up
    rm -f $OBS_Package/*

    cp prepare_source/archives/libzen_${Version_new}.tar.xz $OBS_Package
    cp prepare_source/archives/libzen_${Version_new}.tar.gz $OBS_Package

    #cp prepare_source/ZL/ZenLib_${Version_new}/Project/GNU/libzen.spec $OBS_Package
    #cp prepare_source/ZL/ZenLib_${Version_new}/Project/GNU/libzen.dsc $OBS_Package/libzen_${Version_new}.dsc
    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.spec $OBS_Package
    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.dsc $OBS_Package/libzen_${Version_new}.dsc
    update_DSC "$ZL_tmp"/$OBS_Package libzen_${Version_new}.tar.xz libzen_${Version_new}.dsc

    cd $OBS_Package
    osc addremove *
    osc commit -n

}

function _obs_deb () {

    # This function build the source on OBS for a specific debian
    # version.

    local debVersion="$1" Comp="$2"
    local OBS_Package="$OBS_Project/ZenLib_$debVersion"

    cd "$ZL_tmp"

    echo
    echo "OBS for $OBS_Package, initialize files..."
    echo

    osc checkout $OBS_Package

    # Clean up
    rm -f $OBS_Package/*

    cp prepare_source/archives/libzen_${Version_new}.tar.$Comp $OBS_Package
    cd $OBS_Package
    tar xf libzen_${Version_new}.tar.$Comp
    rm -fr ZenLib/debian
    mv ZenLib/Project/OBS/${debVersion}.debian ZenLib/debian
    if [ "$Comp" = "xz" ]; then
        (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libzen_${Version_new}.tar.xz ZenLib)
    elif [ "$Comp" = "gz" ]; then
        (GZIP=-9 tar -cz --owner=root --group=root -f libzen_${Version_new}.tar.gz ZenLib)
    fi
    rm -fr ZenLib
    cd ../..

    #cp prepare_source/ZL/ZenLib_${Version_new}/Project/OBS/${debVersion}.dsc $OBS_Package/libzen_${Version_new}.dsc
    cp prepare_source/ZL/ZenLib/Project/OBS/${debVersion}.dsc $OBS_Package/libzen_${Version_new}.dsc
    update_DSC "$ZL_tmp"/$OBS_Package libzen_${Version_new}.tar.$Comp libzen_${Version_new}.dsc

    cd $OBS_Package
    osc addremove *
    osc commit -n

}

function _linux () {

        if b.opt.has_flag? --log; then
            _obs > "$Log"/linux.log 2>&1
            _obs_deb deb6 gz >> "$Log"/linux.log 2>&1
        else
            _obs
            _obs_deb deb6 gz
        fi

        python $(b.get bang.working_dir)/update_Linux_DB.py $OBS_Project ZenLib $Version_new "$ZLB_dir" > "$Log"/obs_python.log 2>&1 &
        # To prevent
        # OSError: [Errno 17] File exists: 'destination'
        sleep 10
        python $(b.get bang.working_dir)/update_Linux_DB.py $OBS_Project ZenLib_deb6 $Version_new "$ZLB_dir" > "$Log"/obs_python_deb6.log 2>&1 &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $WDir/`date +%Y%m%d`; then
    #    mv $WDir/`date +%Y%m%d` $WDir/`date +%Y%m%d`-1
    #    WDir=$WDir/`date +%Y%m%d`-2
    #    mkdir -p $WDir
    # + handle a third run, etc
        
    local ZLB_dir="$WDir"/binary/libzen0/$subDir
    local ZLS_dir="$WDir"/source/libzen/$subDir
    local ZL_tmp="$WDir"/tmp/libzen/$subDir

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
        _linux
        mv "$ZL_tmp"/prepare_source/archives/libzen_${Version_new}.* "$ZLS_dir"
    fi

    if $CleanUp; then
        rm -fr "$ZL_tmp"
    fi

}
