# ZenLib/Release/BuildRelease.sh
# Build a release of ZenLib

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _obs () {

    local OBS_package="$OBS_project/ZenLib"

    cd "$ZL_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/libzen_${Version_new}.tar.xz $OBS_package/libzen_${Version_new}.orig.tar.xz
    # Suse doesn’t handle xz
    cp prepare_source/archives/libzen_${Version_new}.tar.gz $OBS_package

    # For Debian : generation of libzen_XXX-1.debian.tar.xz
    cd $OBS_package
    tar xf libzen_${Version_new}.orig.tar.xz
    mv ZenLib/debian .
    rm -fr ZenLib
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libzen_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.spec $OBS_package
    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.dsc $OBS_package/libzen_${Version_new}-1.dsc
    cp prepare_source/ZL/ZenLib/Project/GNU/PKGBUILD $OBS_package

    update_DSC "$ZL_tmp"/$OBS_package libzen_${Version_new}.orig.tar.xz libzen_${Version_new}-1.dsc
    update_DSC "$ZL_tmp"/$OBS_package libzen_${Version_new}-1.debian.tar.xz libzen_${Version_new}-1.dsc
    
    update_PKGBUILD "$ZL_tmp"/$OBS_package libzen_${Version_new}.orig.tar.xz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb () {

    # This function build the source on OBS for a specific Debian
    # version.

    local Deb_version="$1"
    local OBS_package="$OBS_project/ZenLib_$Deb_version"

    cd "$ZL_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    # Gestion of specific /debian/
    cp prepare_source/archives/libzen_${Version_new}.tar.xz $OBS_package
    cd $OBS_package
    tar xf libzen_${Version_new}.tar.xz
    rm -fr libzen_${Version_new}.tar.xz
    rm -fr ZenLib/debian ; mv ZenLib/Project/OBS/${Deb_version}.debian ZenLib/debian
    cp -r ZenLib/debian .
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libzen_${Version_new}.orig.tar.xz ZenLib)
    rm -fr ZenLib
    (XZ_OPT=-9e tar -cJ --owner=root --group=root -f libzen_${Version_new}-1.debian.tar.xz debian)
    rm -fr debian
    cd ../..

    cp prepare_source/ZL/ZenLib/Project/OBS/${Deb_version}.dsc $OBS_package/libzen_${Version_new}-1.dsc

    update_DSC "$ZL_tmp"/$OBS_package libzen_${Version_new}.orig.tar.xz libzen_${Version_new}-1.dsc
    update_DSC "$ZL_tmp"/$OBS_package libzen_${Version_new}-1.debian.tar.xz libzen_${Version_new}-1.dsc

    cd $OBS_package
    osc addremove *
    osc commit -n

}

function _obs_deb6 () {

    # This function build the source on OBS for Debian 6.

    local OBS_package="$OBS_project/ZenLib_deb6"

    cd "$ZL_tmp"

    echo
    echo "OBS for $OBS_package, initialize files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/libzen_${Version_new}.tar.gz $OBS_package
    cd $OBS_package
    tar xf libzen_${Version_new}.tar.gz
    rm -fr ZenLib/debian ; mv ZenLib/Project/OBS/deb6.debian ZenLib/debian
    (GZIP=-9 tar -cz --owner=root --group=root -f libzen_${Version_new}.tar.gz ZenLib)
    rm -fr ZenLib
    cd ../..

    cp prepare_source/ZL/ZenLib/Project/OBS/deb6.dsc $OBS_package/libzen_${Version_new}.dsc

    update_DSC "$ZL_tmp"/$OBS_package libzen_${Version_new}.tar.gz libzen_${Version_new}.dsc

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
    echo python Handle_OBS_results.py $OBS_project ZenLib $Version_new "$ZLB_dir"
    echo

    # To avoid "os.getcwd() failed: No such file or directory" if
    # $Clean_up is set (ie "$ZL_tmp", the current directory, will
    # be deleted)
    cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
    python Handle_OBS_results.py $OBS_project ZenLib $Version_new "$ZLB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    # The sleep is to avoid OSError: File exists: 'destination'
    sleep 10
    python Handle_OBS_results.py $OBS_project ZenLib_deb6 $Version_new "$ZLB_dir" >"$Log"/obs_deb6.log 2>"$Log"/obs_deb6-error.log &
    sleep 10
    python Handle_OBS_results.py $OBS_project ZenLib_deb9 $Version_new "$ZLB_dir" >"$Log"/obs_deb9.log 2>"$Log"/obs_deb9-error.log &

}

function btask.BuildRelease.run () {

    # TODO: incremental snapshots if multiple execution in the
    # same day eg. AAAAMMJJ-X
    #if b.path.dir? $Working_dir/`date +%Y%m%d`; then
    #    mv $Working_dir/`date +%Y%m%d` $Working_dir/`date +%Y%m%d`-1
    #    Working_dir=$Working_dir/`date +%Y%m%d`-2
    #    mkdir -p $Working_dir
    # + handle a third run, etc

    local Repo
    local ZLB_dir="$Working_dir"/binary/libzen0/$Sub_dir
    local ZLS_dir="$Working_dir"/source/libzen/$Sub_dir
    local ZL_tmp="$Working_dir"/tmp/libzen/$Sub_dir

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

    if [ $(b.opt.get_opt --repo) ]; then
        Repo="$(sanitize_arg $(b.opt.get_opt --repo))"
    else
        Repo="https://github.com/MediaArea/Zenlib"
    fi

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$ZL_tmp"/upgrade_version/ZenLib
    else
        git -C "$ZL_tmp"/upgrade_version clone "$Repo"
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        git -C "$ZL_tmp"/upgrade_version/ZenLib checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $ZL_tmp/upgrade_version/ZenLib/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p zl -n $Version_new -sp "$ZL_tmp"/upgrade_version/ZenLib

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p zl -v $Version_new -wp "$ZL_tmp"/prepare_source -sp "$ZL_tmp"/upgrade_version/ZenLib -sa -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ]; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$ZL_tmp"/prepare_source/archives/libzen_${Version_new}.* "$ZLS_dir"
    fi

    if $Clean_up; then
        rm -fr "$ZL_tmp"
    fi

}
