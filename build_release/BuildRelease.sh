#!/usr/bin/env bang run

# MediaArea-Utils/buildrelease/BuildRelease.sh
# Build releases of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that
# can be found in the License.txt file in the root of the source
# tree.

# This script requires: bang.sh UpgradeVersion.sh PrepareSource.sh 
#                        ssh mawk osc rpm-common

function load_options () {

    b.opt.add_flag --help "Show this help"
    b.opt.add_alias --help -h
    
    b.opt.add_opt --project "The project to work with"
    b.opt.add_alias --project -p

    b.opt.add_opt --new "New version of the project"
    b.opt.add_alias --new -n

    b.opt.add_flag --snapshot "Make a snapshot"
    b.opt.add_alias --snapshot -s

    b.opt.add_opt --working-path "Specify working path (otherwise /tmp)"
    b.opt.add_alias --working-path -wp

    b.opt.add_opt --source-path "Source directory to modify"
    b.opt.add_alias --source-path -sp

    b.opt.add_opt --repo "Source repository URL"
    b.opt.add_alias --repo -r

    b.opt.add_opt --git-state "Ask for a specific git state of the current project"
    b.opt.add_alias --git-state -gs

    b.opt.add_opt --mil-gs "Ask for a specific git state for the MIL dependency"
    b.opt.add_opt --zl-gs "Ask for a specific git state for the ZL dependency"

    b.opt.add_opt --zl-version "Update the ZL version to depend on"

    b.opt.add_flag --keep-mil-dep "(In release mode) Don't autoincrement the MIL requested version to the latest detected one"

    b.opt.add_flag --build-mac "Build only for Mac"
    b.opt.add_alias --build-mac -bm

    b.opt.add_flag --build-windows "Build only for Windows"
    b.opt.add_alias --build-windows -bw

    b.opt.add_flag --build-linux "Build only for Linux"
    b.opt.add_alias --build-linux -bl

    b.opt.add_flag --all "Build all the targets for a project"
    # Same arguments as PrepareSource.sh
    b.opt.add_alias --all -all

    b.opt.add_flag --log "Log the output in a file instead of display it"

    b.opt.add_flag --no-cleanup "Don’t erase the temporary directories"
    b.opt.add_alias --no-cleanup -nc

    b.opt.add_flag --commit "Commit the changes made by UpgradeVersion.sh on git"
    b.opt.add_alias --commit -c

    b.opt.add_flag --force "Force run even if the master is older than the last build"
    b.opt.add_alias --force -f

    # Mandatory arguments
    b.opt.required_args --project
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function update_PKGBUILD () {

    # Arguments :
    # update_PKGBUILD $Path_to_obs_project $Archive $PKGBUILD
    
    # TODO: Handle more than one file in PKGBUILD
    # TODO: Handle sha1sum & sha256sum arrays
    
    local OBSPath=$1 Archive=$2 PKGBUILD=$3

    PKGBUILD="$OBSPath"/$PKGBUILD

    if [ $# -lt 3 ]; then
        echo "Insuffisent parameters for update_PKGBUILD"
        exit 1
    fi

    OldMD5="00000000000000000000000000000000"
    MD5=`md5sum "$OBSPath"/$Archive |awk '{print $1}'`

    if b.path.file? "$PKGBUILD" && b.path.readable? "$PKGBUILD"; then
        $(sed -i "s/$OldMD5/$MD5/g" "$PKGBUILD")
    else
       print_e "WARNING: file ${PKGBUILD} not found"
    fi
}

function run () {
    load_options
    b.opt.init "$@"

    # Display help
    if b.opt.has_flag? --help; then
        b.opt.show_usage
        exit 1
    fi
    
    if b.opt.check_required_args; then

        project_get

        Date=`date +%Y%m%d`

        # Load sensible configuration we don’t want on github
        source "$(dirname ${BASH_SOURCE[0]})"/Config.sh

        Target="all"
        PS_target="-all"
        if b.opt.has_flag? --build-mac; then
            Target="mac"
            PS_target="-cu"
        fi
        if b.opt.has_flag? --build-windows; then
            Target="windows"
            PS_target="-cw"
        fi
        if b.opt.has_flag? --build-linux; then
            Target="linux"
            PS_target="-sa"
        fi

        # TODO: Handle exception if /tmp not writable
        # In case --working-path is not defined
        Working_dir=/tmp
        # In case it is
        if [ $(b.opt.get_opt --working-path) ]; then
            Working_dir="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? "$Working_dir" && ! b.path.writable? "$Working_dir"; then
                echo
                echo "The directory $Working_dir isn’t writable : will use /tmp instead."
                echo
                Working_dir=/tmp/
            else
                if ! b.path.dir? $Working_dir ;then
                    if ! mkdir -p $Working_dir ; then
                        echo
                        echo "Unable to create directory $Working_dir : will use /tmp instead."
                        echo
                        Working_dir=/tmp/
                    fi
                fi
            fi
        fi

        if [ $(b.opt.get_opt --source-path) ]; then
            Source_dir="$(sanitize_arg $(b.opt.get_opt --source-path))"
            if ! b.path.dir? "$Source_dir"; then
                echo
                echo "The directory $Source_dir doesn’t exist!"
                echo
                exit 1
            fi
        fi

        Clean_up=true
        if b.opt.has_flag? --no-cleanup; then
            Clean_up=false
        fi

        if b.opt.has_flag? --snapshot ; then
            # Test if the project was modified since the last build
            local Last_commit="$(git ls-remote $Repo master | cut -f1)"
            local Rebuild=false

            if b.path.file? "$Working_dir/log/$Project/last_commit" \
            && [ "$(cat $Working_dir/log/$Project/last_commit 2>/dev/null)" ==  $Last_commit ] ; then
                if ! b.opt.has_flag? --force; then
                    echo "Master is older than the last build"
                    exit 0
                fi
                Rebuild=true
            fi

            Sub_dir="${Date}"
            local Index=2
            local Found="$Sub_dir"
            while [ "$(find ${Working_dir}/binary ${Working_dir}/source ${Working_dir}/tmp \
                    \( -regex .*/${Dirname}0?/${Sub_dir} -o -regex .*/${Dirname}-*/${Sub_dir} \) \
                    -printf 1 -quit)" == "1" ]
            do
                Found="$Sub_dir"
                Sub_dir="$Date-$Index"
                let Index++
            done

            if $Rebuild ; then
                Sub_dir="$Found"
            fi

            echo $Last_commit > $Working_dir/log/$Project/last_commit

            Mac_working_dir="${Mac_working_dir}/snapshots"
            OBS_project="${OBS_project}:snapshots"
        elif [ $(b.opt.get_opt --new) ] ; then
            Sub_dir="$(sanitize_arg $(b.opt.get_opt --new))"
            Mac_working_dir="${Mac_working_dir}/releases"
        else
            echo
            echo "If you don’t ask a snapshot, you must provide"
            echo "the new version of the release (with --new)"
            echo
            exit 1
        fi

        Log="$Working_dir"/log/$Project/$Sub_dir
        if ! b.path.dir? "$Log"; then
            mkdir -p "$Log"
        fi

        Script="$(dirname ${BASH_SOURCE[0]})/../${Project}/BuildRelease.sh"
        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, so bang can find
            # the corresponding task
            . $Script
            if b.opt.has_flag? --log; then
                b.task.run BuildRelease > "$Log"/init.log 2> "$Log"/init-error.log
            else
                echo
                b.task.run BuildRelease
                echo
            fi
        else
            echo
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in BuildRelease.sh’s directory to launch it."
            echo "e.g. /path/to/MediaArea-Utils/buildrelease"
            echo "and the project repository must be in the same directory than MediaArea-Utils"
            echo
        fi

        unset -v Project Repo
        unset -v Date Version_old Version_new
        unset -v OBS_project Target PS_target
        unset -v Working_dir Source_dir Sub_dir
        unset -v Mac_working_dir Email_to Email_CC
        unset -v Mac_IP Mac_SSH_port Mac_SSH_user Key_chain
        unset -v Win_IP Win_SSH_port Win_SSH_user
        unset -v Clean_up Log Script
    fi
}

# Import globals modules
b.module.append_lookup_dir $(dirname ${BASH_SOURCE[0]})/../modules
b.module.require project

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
