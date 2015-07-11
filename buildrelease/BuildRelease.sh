#!/usr/bin/env bang run

# MediaArea-Utils/buildrelease/BuildRelease.sh
# Build releases of the projects used by MediaArea

# Copyright (c) MediaArea.net SARL. All Rights Reserved.
# Use of this source code is governed by a BSD-style license that can
# be found in the License.txt file in the root of the source tree.

# This script requires : bang.sh UpgradeVersion.sh PrepareSource.sh 
#                         ssh

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
    b.opt.add_alias --working-path -w

    b.opt.add_flag --build-mac "Build only for Mac"
    b.opt.add_alias --build-mac -bm

    b.opt.add_flag --build-windows "Build only for Windows"
    b.opt.add_alias --build-windows -bw

    b.opt.add_flag --build-linux "Build only for Linux"
    b.opt.add_alias --build-linux -bl

    b.opt.add_flag --all "Build all the targets for this project"
    # Same arguments as PrepareSource.sh
    b.opt.add_alias --all -all

    b.opt.add_flag --no-cleanup "Don’t erase the temporary directories"
    b.opt.add_alias --no-cleanup -nc

    # Mandatory arguments
    b.opt.required_args --project --old
}

function displayHelp () {
    b.raised_message
    b.opt.show_usage
}

function run () {
    load_options
    b.opt.init "$@"

    # Display help
    if b.opt.has_flag? --help; then
        b.opt.show_usage
        exit
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

        Version_old=$(sanitize_arg $(b.opt.get_opt --old))

        Snapshot="no"
        if b.opt.has_flag? --snapshot; then
            Snapshot="yes"
            Version_new="${Version_old}.`date +%Y%m%d`"
        elif [ $(b.opt.get_opt --new) ]; then
            Version_new=$(sanitize_arg $(b.opt.get_opt --new))
        else
            echo
            echo "If you don't ask a snapshot, you must provide"
            echo "the new version of the release (with --new)"
            echo
            exit
        fi

        Target="all"
        if b.opt.has_flag? --build-mac; then
            Target="mac"
        fi
        if b.opt.has_flag? --build-windows; then
            Target="windows"
        fi
        if b.opt.has_flag? --build-linux; then
            Target="linux"
        fi

        WPath=/tmp
        if [ $(b.opt.get_opt --working-path) ]; then
            WPath="$(sanitize_arg $(b.opt.get_opt --working-path))"
            if b.path.dir? $WPath && ! b.path.writable? $WPath; then
                echo "The directory $WPath isn't writable : will use /tmp instead."
                echo
                WPath=/tmp/
            else
                # TODO: Handle exception if mkdir fail
                if ! b.path.dir? $WPath ;then
                    mkdir -p $WPath
                fi
            fi
        fi

        CleanUp=true
        if b.opt.has_flag? --no-cleanup; then
            CleanUp=false
        fi

        . Config.sh

        # For lisibility
        echo

        # TODO: possibility to run the script from anywhere
        #Script="$(b.get bang.working_dir)/../../${Project}/Release/BuildRelease.sh"
        Script="$(b.get bang.working_dir)/../${Project}/BuildRelease.sh"
        # If the user give a correct project name
        if b.path.file? $Script && b.path.readable? $Script; then
            # Load the script for this project, so bang can find the
            # corresponding task, then launch it
            . $Script
            b.task.run BuildRelease
        else
            echo "Error : no task found for $Project!"
            echo
            echo "Warning : you must be in BuildRelease.sh's directory to launch it."
            echo "e.g. /path/to/MediaArea-Utils/buildrelease"
            echo "and the project repository must be in the same directory than MediaArea-Utils"
        fi

        # For lisibility
        echo

        #unset -v Project Release_date Script
        unset -v Project Version_old Version_new Snapshot Target WPath
        unset -v CleanUp Script
    fi
}

b.try.do run "$@"
b.catch RequiredOptionNotSet displayHelp
b.try.end