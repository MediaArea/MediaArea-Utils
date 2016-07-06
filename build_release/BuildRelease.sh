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

    b.opt.add_opt --old "Old version of the project"
    b.opt.add_alias --old -o

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

    # Mandatory arguments
    b.opt.required_args --project --old
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function update_DSC () {

    # Arguments :
    # update_DSC $Path_to_obs_project $Archive $DSC
    
    local OBSPath=$1 Archive=$2 DSC=$3
    
    DSC="$OBSPath"/$DSC

    if [ $# -lt 3 ]; then
        echo "Insuffisent parameters for update_DSC"
        exit 1
    fi
    
    Size=`ls -l "$OBSPath"/$Archive |awk '{print $5}'`
    SHA1=`sha1sum "$OBSPath"/$Archive |awk '{print $1}'`
    SHA256=`sha256sum "$OBSPath"/$Archive |awk '{print $1}'`
    MD5=`md5sum "$OBSPath"/$Archive |awk '{print $1}'`
    
    # For sed, 00* = 0+
    oldSHA1="0000000000000000000000000000000000000000 00* $Archive"
    oldSHA256="0000000000000000000000000000000000000000000000000000000000000000 00* $Archive"
    oldMD5="00000000000000000000000000000000 00* $Archive"

    newSHA1="$SHA1 $Size $Archive"
    newSHA256="$SHA256 $Size $Archive"
    newMD5="$MD5 $Size $Archive"
    
    # TODO: handle exception if file not found
    if b.path.file? "$DSC" && b.path.readable? "$DSC"; then
        # Handle the longuest strings first, otherwise the shorters
        # get in the way
        $(sed -i "s/${oldSHA256}/$newSHA256/g" "$DSC")
        $(sed -i "s/${oldSHA1}/$newSHA1/g" "$DSC")
        $(sed -i "s/${oldMD5}/$newMD5/g" "$DSC")
    fi

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

    # TODO: handle exception if file not found
    if b.path.file? "$PKGBUILD" && b.path.readable? "$PKGBUILD"; then
        $(sed -i "s/$OldMD5/$MD5/g" "$PKGBUILD")
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

        Project=$(sanitize_arg $(b.opt.get_opt --project))
        if [ "$Project" = "zl" ] || [ "$Project" = "ZL" ]; then
            Project=ZenLib
        fi
        if [ "$Project" = "mil" ] || [ "$Project" = "MIL" ]; then
            Project=MediaInfoLib
        fi
        if [ "$Project" = "mi" ] || [ "$Project" = "MI" ]; then
            Project=MediaInfo
        fi
        if [ "$Project" = "mc" ] || [ "$Project" = "MC" ] || [ "$Project" = "MediaConch" ]; then
            Project=MediaConch_SourceCode
        fi

        Date=`date +%Y%m%d`

        Version_old=$(sanitize_arg $(b.opt.get_opt --old))

        # Load sensible configuration we don’t want on github
        . Config.sh    

        if b.opt.has_flag? --snapshot; then
            Version_new="${Version_old}.$Date"
            Sub_dir="$Date"
            Mac_working_dir="${Mac_working_dir}/snapshots"
            OBS_project="${OBS_project}:snapshots"
        elif [ $(b.opt.get_opt --new) ]; then
            Version_new=$(sanitize_arg $(b.opt.get_opt --new))
            Sub_dir="$Version_new"
            Mac_working_dir="${Mac_working_dir}/releases"
        else
            echo
            echo "If you don’t ask a snapshot, you must provide"
            echo "the new version of the release (with --new)"
            echo
            exit 1
        fi

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

        # In case --working-path is not defined
        Working_dir=/tmp
        # In case it is
        if [ $(b.opt.get_opt --working-path) ]; then
            Working_dir="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? "$Working_dir" && ! b.path.writable? "$Working_dir"; then
                echo
                echo "The directory $Working_dir isn’t writable : will use /tmp instead."
                echo
                Working_dir=/tmp
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
        
        # TODO: Handle exception if mkdir fail (/tmp not writable)
        if ! b.path.dir? "$Working_dir"; then
            mkdir -p "$Working_dir"
        fi

        Log="$Working_dir"/log/$Project/$Sub_dir
        if ! b.path.dir? "$Log"; then
            mkdir -p "$Log"
        fi

        # TODO: possibility to run the script from anywhere
        #Script="$(b.get bang.working_dir)/../../${Project}/Release/BuildRelease.sh"
        Script="$(b.get bang.working_dir)/../${Project}/BuildRelease.sh"
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

        unset -v Project Date Version_old Version_new
        unset -v OBS_project Target PS_target
        unset -v Working_dir Source_dir Sub_dir
        unset -v Mac_working_dir Email_to Email_CC
        unset -v Mac_IP Mac_SSH_port Mac_SSH_user Key_chain
        unset -v Win_IP Win_SSH_port Win_SSH_user
        unset -v Clean_up Log Script
    fi
}

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end
