# RAWcooked/Release/BuildRelease.sh
# Build a release of RAWcooked

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.html file in the root of the source
# tree.

function _mac_cli () {
    local DLPath File

    cd "$RC_tmp"

    # Clean up
    $SSHP "test -d $Mac_working_dir || mkdir $Mac_working_dir
           cd $Mac_working_dir
           rm -fr RAWcooked_CLI*"

    echo
    echo "Compile RC CLI for mac..."
    echo

    scp -P $Mac_SSH_port prepare_source/archives/RAWcooked_CLI_${Version_new}_GNU_FromSource.tar.xz $Mac_SSH_user@$Mac_IP:$Mac_working_dir/RAWcooked_CLI_${Version_new}_GNU_FromSource.tar.xz

    $SSHP "cd $Mac_working_dir
           tar xf RAWcooked_CLI_${Version_new}_GNU_FromSource.tar.xz
           cd RAWcooked_CLI_GNU_FromSource
           ./Project/Mac/BR_extension_CLI.sh
           test -x Project/GNU/CLI/rawcooked || exit 1
           $Key_chain
           cd Project/Mac
           ./mkdmg.sh RAWcooked cli $Version_new"

    DLPath="$Mac_working_dir/RAWcooked_CLI_GNU_FromSource/Project/Mac"
    File="RAWcooked_CLI_${Version_new}_Mac.dmg"
    test -e "$RCB_dir"/$File && rm "$RCB_dir"/$File
    scp -P $Mac_SSH_port $Mac_SSH_user@$Mac_IP:$DLPath/$File "$RCB_dir" || MSG="${MSG}Failed to retreive file ${File} build failed ?\n"
}

function _mac () {

    local SSHP

    SSHP="ssh -x -p $Mac_SSH_port $Mac_SSH_user@$Mac_IP"

    _mac_cli

    # Check non fatals errors
    if [ -n "$MSG" ]; then
        print_e "$MSG"
        return 1
    fi
}

function _obs () {

    local OBS_package="$OBS_project/RAWcooked"

    cd "$RC_tmp"

    echo
    echo "Initialize OBS files..."
    echo

    osc checkout $OBS_package

    # Clean up
    rm -f $OBS_package/*

    cp prepare_source/archives/obs/* $OBS_package

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
        echo python Handle_OBS_results.py $Filter $OBS_project RAWcooked $Version_new "$RCB_dir" "$RCG_dir"
        echo

        # To avoid "os.getcwd() failed: No such file or directory" if
        # $Clean_up is set (ie "$RC_tmp", the current directory, will
        # be deleted)
        cd "$(dirname ${BASH_SOURCE[0]})/../build_release"
        python Handle_OBS_results.py $Filter $OBS_project RAWcooked $Version_new "$RCB_dir" "$RCG_dir" >"$Log"/obs_main.log 2>"$Log"/obs_main-error.log &
    else
        echo "#!/bin/bash" > "$WORKSPACE/STAGE"
        echo "python Handle_OBS_results.py $Filter $OBS_project RAWcooked $Version_new \"$RCB_dir\" \"$RCG_dir\"" > "$WORKSPACE/STAGE"
        chmod +x "$WORKSPACE/STAGE"
    fi

}

function btask.BuildRelease.run () {

    local UV_flags
    local RCB_dir="$Working_dir"/binary/rawcooked/$Sub_dir
    local RCS_dir="$Working_dir"/source/rawcooked/$Sub_dir
    local RC_tmp="$Working_dir"/tmp/rawcooked/$Sub_dir

    echo
    echo Clean up...
    echo

    rm -fr "$RC_tmp"

    mkdir -p "$RCB_dir"

    mkdir -p "$RCS_dir"
    mkdir -p "$RC_tmp"

    cd "$RC_tmp"
    mkdir upgrade_version
    mkdir prepare_source

    cd "$(dirname ${BASH_SOURCE[0]})/../upgrade_version"
    if [ $(b.opt.get_opt --source-path) ]; then
        # Made a copy, because UV.sh -sp modify the files in place
        cp -r "$Source_dir" "$RC_tmp"/upgrade_version/RAWcooked
    else
        pushd "$RC_tmp"/upgrade_version
        git clone "$Repo" RAWcooked
        popd
    fi

    if [ $(b.opt.get_opt --git-state) ]; then
        pushd  "$RC_tmp"/upgrade_version/RAWcooked
        git checkout "$(sanitize_arg $(b.opt.get_opt --git-state))"
        popd
    fi

    if b.opt.has_flag? --snapshot ; then
        Version_new="$(cat $RC_tmp/upgrade_version/RAWcooked/Project/version.txt).$Date"
    else
        Version_new="$(sanitize_arg $(b.opt.get_opt --new))"
    fi

    UV_flags=""
    if b.opt.has_flag? --commit ; then
        UV_flags="-c"
    fi

    $(b.get bang.src_path)/bang run UpgradeVersion.sh -p rc -n $Version_new $UV_flags -sp "$RC_tmp"/upgrade_version/RAWcooked

    cd "$(dirname ${BASH_SOURCE[0]})/../prepare_source"

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        find "$RCS_dir" -name 'rawcooked*.tar.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        find "$RCB_dir" "$RCG_dir" -name 'RAWcooked_*_GNU_FromSource.*' -mindepth 1 -delete
    fi
    if [ "$Target" = "windows" ] || [ "$Target" = "all" ] ; then
        find "$RCS_dir" -name 'rawcooked_*.7z' -mindepth 1 -delete
    fi

    # Do NOT remove -nc, mandatory for the .dsc and .spec
    $(b.get bang.src_path)/bang run PrepareSource.sh -p rc -v $Version_new -wp "$RC_tmp"/prepare_source -sp "$RC_tmp"/upgrade_version/RAWcooked -nc

    if [ "$Target" = "linux" ] || [ "$Target" = "all" ] ; then
        if b.opt.has_flag? --log; then
            _linux >"$Log"/linux.log 2>"$Log"/linux-error.log
        else
            _linux
        fi
        mv "$RC_tmp"/prepare_source/archives/rawcooked_${Version_new}.tar.* "$RCS_dir"
    fi
    if [ "$Target" = "mac" ] || [ "$Target" = "all" ] ; then
        MSG=
        if b.opt.has_flag? --log; then
            _mac >"$Log"/mac.log 2>"$Log"/mac-error.log
        else
            _mac
        fi

        if [ $? -ne 0 ] ; then
            echo -e "$MSG" | mailx -s "[BR Mac] Problem building RAWcooked" ${Email_CC/$Email_CC/-c $Email_CC} $Email_to
        fi

        mv "$RC_tmp"/prepare_source/archives/RAWcooked_CLI_${Version_new}_GNU_FromSource.* "$RCB_dir"
    fi

    if $Clean_up; then
        rm -fr "$RC_tmp"
    fi

}
