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

    # Create Debian packages and dsc
    deb_obs "$ZL_tmp"/$OBS_package libzen_${Version_new}.orig.tar.xz

    cp prepare_source/ZL/ZenLib/Project/GNU/libzen.spec $OBS_package
    cp prepare_source/ZL/ZenLib/Project/GNU/PKGBUILD $OBS_package

    update_PKGBUILD "$ZL_tmp"/$OBS_package libzen_${Version_new}.orig.tar.xz PKGBUILD

    cd $OBS_package
    osc addremove *
    osc commit -n
}


function _linux () {

    _obs

    if ! b.opt.has_flag? --jenkins ; then
        echo
        echo Launch in background the python script which check
        echo the build results and download the packages...
        echo
        echo The command line is:
        echo python Handle_OBS_results.py $Filter $OBS_project ZenLib $Version_new "$ZLB_dir"
        echo

        # To avoid "os.getcwd() failed: No such file or directory" if
        # $Clean_up is set (ie "$ZL_tmp", the current directory, will
        # be deleted)
        cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
        python Handle_OBS_results.py $Filter $OBS_project ZenLib $Version_new "$ZLB_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    else
        echo "#!/bin/bash" > "$WORKSPACE/STAGE"
        echo "python Handle_OBS_results.py $Filter $OBS_project ZenLib $Version_new \"$ZLB_dir\"" >> "$WORKSPACE/STAGE"
        chmod +x "$WORKSPACE/STAGE"
    fi
}

function btask.BuildRelease.run () {

    local UV_flags
    local ZLB_dir="$Working_dir"/binary/libzen0/$Sub_dir
    local ZLS_dir="$Working_dir"/source/libzen/$Sub_dir
    local ZL_tmp="$Working_dir"/tmp/libzen/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$ZL_tmp"

    mkdir -p "$ZLB_dir"

    mkdir -p "$ZLS_dir"
    mkdir -p "$ZL_tmp"

    cd "$ZL_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$ZL_tmp"/upgrade_version/ZenLib
    else
        pushd "$ZL_tmp"/upgrade_version
        git clone "$Repo" ZenLib
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$ZL_tmp"/upgrade_version/ZenLib
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $ZL_tmp/upgrade_version/ZenLib/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p zl -n $Version_new $UV_flags -sp "$ZL_tmp"/upgrade_version/ZenLib

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"
    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$ZLS_dir" -name 'libzen_*.tar.*' -mindepth 1 -delete
    fi

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
